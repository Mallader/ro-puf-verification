timeunit 1ns;
timeprecision 1ps;

module ro_module_driver  (
    ro_pair_measure_if.drv_mp vif
);

    localparam BUSY_TIMEOUT_CYCLES = 200;
    localparam DONE_TIMEOUT_CYCLES = 200;

    localparam int DONE_HOLD_CYCLES = 3;

    bit success = 0;
    int unsigned cycles_waited = 0;

    task automatic apply_reset(int unsigned hold_cycles);
        vif.drv_cb.rst_n <= 1'b0;
        repeat (hold_cycles) @(vif.drv_cb);
        vif.drv_cb.rst_n <= 1'b1;
    endtask

    task automatic send_start(int unsigned hold_cycles);
        vif.drv_cb.start     <= 1'b1;
        repeat (hold_cycles) @(vif.drv_cb);
        vif.drv_cb.start     <= 1'b0;
    endtask

    task automatic wait_for_busy(
        input  int unsigned timeout_cycles,
        output bit          success,
        output int unsigned cycles_waited
    );
        success = 0;
        cycles_waited = 0;
        
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            if (vif.drv_cb.busy === 1'b1) begin
                success = 1;
                break;
            end
            else begin 
                @(vif.drv_cb);
                cycles_waited++;
            end
       end
    endtask

    task automatic wait_for_done(
        input  int unsigned timeout_cycles,
        output bit          success,
        output int unsigned cycles_waited
    );
        success = 0;
        cycles_waited = 0;
        
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            if (vif.drv_cb.done === 1'b1) begin
                success = 1;
                break;
            end
            else begin 
                @(vif.drv_cb);
                cycles_waited++;
            end
       end
    endtask

    initial begin
        vif.drv_cb.start     <= 0;
        apply_reset(2);
        send_start(1);

        wait_for_busy(BUSY_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "BUSY TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display("first BUSY detected");

        wait_for_done(DONE_TIMEOUT_CYCLES, success, cycles_waited);
        if (!success)
            $fatal(1,
                "done TIMEOUT after %0d cycles",
                cycles_waited
            );

        $display(
            "first done detected after %0d cycles",
            cycles_waited
        );

        repeat (DONE_HOLD_CYCLES) @(vif.drv_cb);
    end

endmodule
