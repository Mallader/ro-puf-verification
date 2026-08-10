timeunit 1ns;
timeprecision 1ps;

module puf_driver_probe  (
    puf_core_if.drv_mp vif
);
    localparam logic [vif.CHALLENGE_WIDTH-1:0] CHALLENGE_1 = 'h3E9;
    localparam logic [vif.CHALLENGE_WIDTH-1:0] CHALLENGE_2 = 'h310;

    localparam BUSY_TIMEOUT_CYCLES  = 10;
    localparam READY_TIMEOUT_CYCLES = 20;

    localparam int READY_HOLD_CYCLES = 3;

    bit success = 0;
    int unsigned cycles_waited = 0;

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

    task automatic wait_for_busy(
        input  int unsigned timeout_cycles,
        output bit          success,
        output int unsigned cycles_waited
    );
        success = 0;
        cycles_waited = 0;

        if (vif.drv_cb.busy === 1'b1) begin
            success = 1;
            return;
        end
        
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            @(posedge vif.clk27);
            cycles_waited++;

            if (vif.drv_cb.busy === 1'b1) begin
                success = 1;
                break;
            end
       end
    endtask

    task automatic wait_for_ready(
        input  int unsigned timeout_cycles,
        output bit          success,
        output int unsigned cycles_waited
    );
        success = 0;
        cycles_waited = 0;

        if (vif.drv_cb.ready === 1'b1) begin
            success = 1;
            return;
        end
        
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            @(posedge vif.clk27);
            cycles_waited++;

            if (vif.drv_cb.ready === 1'b1) begin
                success = 1;
                break;
            end
       end
    endtask

    initial begin
        //обычная операция
        vif.drv_cb.start     <= 0;
        vif.drv_cb.challenge <= 0;
        apply_reset(2);
        send_start(CHALLENGE_1);

        wait_for_busy(BUSY_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "BUSY TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display("BUSY detected");

        wait_for_ready(READY_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "READY TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display(
            "READY detected after %0d cycles",
            cycles_waited
        );

        repeat (READY_HOLD_CYCLES) @(posedge vif.clk27);

        //обычная операция
        send_start(CHALLENGE_2);

        wait_for_busy(BUSY_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "BUSY TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display("BUSY detected");

        wait_for_ready(READY_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "READY TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display(
            "READY detected after %0d cycles",
            cycles_waited
        );
    end

endmodule
