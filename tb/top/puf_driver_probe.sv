timeunit 1ns;
timeprecision 1ps;

module puf_driver_probe  (
    puf_core_if.drv_mp vif
);
    localparam logic [vif.CHALLENGE_WIDTH-1:0] CHALLENGE_1 = 'h3E9;
    localparam logic [vif.CHALLENGE_WIDTH-1:0] CHALLENGE_2 = 'h310;
    localparam logic [vif.CHALLENGE_WIDTH-1:0] CHALLENGE_3 = 'h311;

    task automatic apply_reset(int unsigned hold_cycles);
        @(negedge vif.clk27);
        #1;
        vif.rst_n = 1'b0;
        repeat (hold_cycles) @(posedge vif.clk27);
        @(negedge vif.clk27);
        #1;
        vif.rst_n = 1'b1;
        @(posedge vif.clk27);
    endtask

    task automatic send_start(logic [vif.CHALLENGE_WIDTH-1:0] challenge);
        @(posedge vif.clk27);
        vif.drv_cb.challenge <= challenge;
        vif.drv_cb.start     <= 1'b1;
        @(posedge vif.clk27);
        vif.drv_cb.start     <= 1'b0;
    endtask

    initial begin
        //обычная операция
        vif.drv_cb.start     <= 0;
        vif.drv_cb.challenge <= 0;
        apply_reset(2);
        send_start(CHALLENGE_1);
        wait (
            vif.drv_cb.busy  === 1'b0 &&
            vif.drv_cb.ready === 1'b1
        );

        //сброс
        apply_reset(2);

        //обычная операция (незавершенная)
        send_start(CHALLENGE_2);
        wait (vif.drv_cb.busy === 1'b1);

        //сброс
        apply_reset(2);

        repeat (3) @(posedge vif.clk27);

        //обычная операция
        send_start(CHALLENGE_3);
        wait (
            vif.drv_cb.busy  === 1'b0 &&
            vif.drv_cb.ready === 1'b1
        );

        repeat (4) @(posedge vif.clk27);
        $finish;
    end

endmodule
