timeunit 1ns;
timeprecision 1ps;

module puf_core_if_clocking_tb;

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

    always_ff @(posedge clk27 or negedge puf_if.rst_n) begin
        if (!puf_if.rst_n) begin
            puf_if.busy          <= 1'b0;
            puf_if.ready         <= 1'b0;
            puf_if.response      <= '0;
            puf_if.debug_count_a <= '0;
            puf_if.debug_count_b <= '0;
        end else begin
            puf_if.busy  <= puf_if.start;
            puf_if.ready <= puf_if.busy;
        end
    end

    event start_driven;

    initial begin: driver_process
        puf_if.rst_n     = 0;
        puf_if.start     = 0;
        puf_if.challenge = 0;

        repeat (2) @(posedge clk27);

        @(negedge clk27) puf_if.rst_n = 1;

        @(puf_if.drv_cb);
            puf_if.drv_cb.start     <= 1;
            puf_if.drv_cb.challenge <= 10'b1010101001;

        -> start_driven;

        @(puf_if.drv_cb);
            puf_if.drv_cb.start     <= 0;

    end

    task automatic expect_cycle(
        input logic  expected_start,
        input logic  expected_busy,
        input logic  expected_ready,
        input string phase_name
    );
        @(puf_if.mon_cb);

        $display(
            "[%0t] %-12s start=%0b busy=%0b ready=%0b",
            $time,
            phase_name,
            puf_if.mon_cb.start,
            puf_if.mon_cb.busy,
            puf_if.mon_cb.ready
        );

        if ({
            puf_if.mon_cb.start,
            puf_if.mon_cb.busy,
            puf_if.mon_cb.ready
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
                puf_if.mon_cb.start,
                puf_if.mon_cb.busy,
                puf_if.mon_cb.ready
            );
        end
    endtask

    initial begin : checker_process
        @start_driven;

        expect_cycle(
            1'b1,
            1'b0,
            1'b0,
            "START"
        );

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

        $display("PUF_CORE_IF CLOCKING TEST PASSED");
        $finish;
    end

    initial begin: monitor_process
        forever begin
            @(puf_if.mon_cb);
                $display(
                    "time=%0t rst_n=%0b start=%0b challenge=%0b busy=%0b ready=%0b",
                    $time,
                    puf_if.mon_cb.rst_n,
                    puf_if.mon_cb.start,
                    puf_if.mon_cb.challenge,
                    puf_if.mon_cb.busy,
                    puf_if.mon_cb.ready
                );
        end
    end

endmodule
