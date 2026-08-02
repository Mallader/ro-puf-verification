module puf_core_model (
    puf_core_if.dut_mp vif
);
    
    always_ff @(posedge vif.clk27 or negedge vif.rst_n) begin
        if (!vif.rst_n) begin
            vif.busy          <= 1'b0;
            vif.ready         <= 1'b0;
            vif.response      <= '0;
            vif.debug_count_a <= '0;
            vif.debug_count_b <= '0;
        end else begin
            vif.busy  <= vif.start;
            vif.ready <= vif.busy;
        end
    end

endmodule

module puf_driver_probe  (
    puf_core_if.drv_mp vif
);

    initial begin
        vif.rst_n             = 0;
        vif.drv_cb.start     <= 0;
        vif.drv_cb.challenge <= 0;

        repeat (2) @(posedge vif.clk27);

        @(negedge vif.clk27) vif.rst_n = 1;

        @(posedge vif.clk27);
            vif.drv_cb.start     <= 1;
            vif.drv_cb.challenge <= 10'b1010101001;

        @(posedge vif.clk27);
            vif.drv_cb.start     <= 0;

    end

endmodule

module puf_monitor_probe (
    puf_core_if.mon_mp vif
);
    initial begin
        forever begin
            @(posedge vif.clk27);
                $display(
                    "time=%0t rst_n=%0b start=%0b challenge=%0b busy=%0b ready=%0b",
                    $time,
                    vif.mon_cb.rst_n,
                    vif.mon_cb.start,
                    vif.mon_cb.challenge,
                    vif.mon_cb.busy,
                    vif.mon_cb.ready
                );
        end
    end
endmodule

module puf_checker_probe (
    puf_core_if.mon_mp vif
);

    task automatic expect_cycle(
        input logic  expected_start,
        input logic  expected_busy,
        input logic  expected_ready,
        input string phase_name
    );
        @(posedge vif.clk27);

        $display(
            "[%0t] %-12s start=%0b busy=%0b ready=%0b",
            $time,
            phase_name,
            vif.mon_cb.start,
            vif.mon_cb.busy,
            vif.mon_cb.ready
        );

        if ({
            vif.mon_cb.start,
            vif.mon_cb.busy,
            vif.mon_cb.ready
        } !== {
            expected_start,
            expected_busy,
            expected_ready
        }) begin
            $fatal(
                1,
                "%s: expected start=%0b busy=%0b ready=%0b, got start=%0b busy=%0b ready=%0b",
                phase_name,
                expected_start,
                expected_busy,
                expected_ready,
                vif.mon_cb.start,
                vif.mon_cb.busy,
                vif.mon_cb.ready
            );
        end
    endtask

    initial begin
        forever begin
            @(posedge vif.clk27);

            if ((vif.mon_cb.start === 1'b1) &&
                (vif.mon_cb.busy  === 1'b0)) begin

                $display("[%0t] Checker detected accepted start", $time);
                break;
            end
        end
                expect_cycle(
                    1'b0,
                    1'b1,
                    1'b0,
                    "BUSY"
                );

                expect_cycle(
                    1'b0,
                    1'b0,
                    1'b1,
                    "READY"
                );

                $display("PUF_CORE_IF MODPORT TEST PASSED");
                $finish;

    end
endmodule

module puf_core_if_modport_tb;

    localparam int TEST_CHALLENGE_WIDTH = 10;
    localparam int TEST_RESPONSE_BITS   = 3;
    localparam int TEST_COUNTER_WIDTH   = 12;

    logic clk27 = 1'b0;

    always #5ns clk27 = ~clk27;


    puf_core_if #(
        .CHALLENGE_WIDTH (TEST_CHALLENGE_WIDTH),
        .RESPONSE_BITS   (TEST_RESPONSE_BITS),
        .COUNTER_WIDTH   (TEST_COUNTER_WIDTH)
    ) puf_if (
        .clk27(clk27)
    );

    puf_core_model dut_model (
        .vif(puf_if)
    );

    puf_driver_probe puf_driver (
        .vif(puf_if)
    );

    puf_monitor_probe puf_monitor (
        .vif(puf_if)
    );

    puf_checker_probe puf_checker (
        .vif(puf_if)
    );

endmodule
