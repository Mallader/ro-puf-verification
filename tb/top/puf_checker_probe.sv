timeunit 1ns;
timeprecision 1ps;

module puf_checker_probe (
    puf_core_if.checker_mp vif
);

    localparam MAX_TEST_CYCLES = 50;

    initial begin
        fork
            check_normal_protocol();
            check_reset_behavior();
            begin
                repeat (MAX_TEST_CYCLES) @(posedge vif.clk27);
                $fatal(1, "TEST TIMEOUT");
            end
        join_any

        disable fork;
        $finish;
    end

    task automatic check_normal_protocol();
        typedef enum {
            WAIT_START,
            WAIT_BUSY,
            WAIT_READY
        } checker_state_e;

        checker_state_e state = WAIT_START;

        int accepted_count  = 0;
        int completed_count = 0;

        logic [vif.RESPONSE_BITS-1:0] saved_response;
        logic [vif.COUNTER_WIDTH-1:0] saved_count_a;
        logic [vif.COUNTER_WIDTH-1:0] saved_count_b;
        logic                         result_hold;

        forever begin
            @(posedge vif.clk27 or negedge vif.rst_n);

            if (completed_count == 2) begin
                if (accepted_count != 2)
                    $fatal(1,
                        "Wrong operation count: accepted=%0d completed=%0d",
                        accepted_count, completed_count
                    );

                $display(
                    "PUF CORE PROCEDURAL TEST PASSED: accepted=%0d completed=%0d",
                    accepted_count, completed_count
                );
                $finish;
            end

            if (vif.rst_n !== 1'b1) begin
                state = WAIT_START;
                result_hold = 1'b0;
            end
            else begin
                case (state)
                    WAIT_START: begin
                        if (vif.mon_cb.start === 1'b1 && vif.mon_cb.busy === 1'b0) begin
                            state = WAIT_BUSY;
                            accepted_count++;
                            result_hold = 1'b0;
                        end
                        else if (result_hold === 1'b1) begin
                            check_result_storage(saved_response, saved_count_a, saved_count_b);
                        end
                    end

                    WAIT_BUSY: begin
                        if (vif.mon_cb.busy === 1'b1) begin
                            if (vif.mon_cb.ready !== 1'b0)
                                $fatal(1, "[%0t] WAIT_BUSY: busy=%b, expected 1, ready=%b, expected 0",
                                $time, vif.mon_cb.busy, vif.mon_cb.ready);
                            state = WAIT_READY;
                        end
                    end

                    WAIT_READY: begin
                        if (vif.mon_cb.ready  === 1'b1) begin
                            if (vif.mon_cb.busy !== 1'b0)
                                $fatal(1, "[%0t] WAIT_READY: busy=%b, expected 0, response =%b, debug_count_a =%b, debug_count_b = %b",
                                $time, vif.mon_cb.busy, vif.mon_cb.ready, vif.mon_cb.response, vif.mon_cb.debug_count_a, vif.mon_cb.debug_count_b);
                            state = WAIT_START;
                            completed_count++;
                            result_hold = 1'b1;
                            saved_response = vif.mon_cb.response;
                            saved_count_a  = vif.mon_cb.debug_count_a;
                            saved_count_b  = vif.mon_cb.debug_count_b;
                        end
                    end

                    default: 
                        state = WAIT_START;
                endcase
            end
        end

    endtask

    task automatic check_result_storage(
        logic [vif.RESPONSE_BITS-1:0] saved_response,
        logic [vif.COUNTER_WIDTH-1:0] saved_count_a,
        logic [vif.COUNTER_WIDTH-1:0] saved_count_b
    );
        if (vif.mon_cb.ready !== 1'b1)
            $fatal(1, "ready changed before new command expected=1 actual=%h", vif.mon_cb.ready);
        if (vif.mon_cb.busy !== 1'b0)
            $fatal(1, "busy changed while READY was held expected=0 actual=%h", vif.mon_cb.busy);
        if (saved_response !== vif.mon_cb.response)
            $fatal(1, "response changed while READY was held expected=%h actual=%h", saved_response, vif.mon_cb.response);
        if (saved_count_a !== vif.mon_cb.debug_count_a)
            $fatal(1, "debug_count_a changed while READY was held expected=%h actual=%h", saved_count_a, vif.mon_cb.debug_count_a);
        if (saved_count_b !== vif.mon_cb.debug_count_b)
            $fatal(1, "debug_count_b changed while READY was held expected=%h actual=%h", saved_count_b, vif.mon_cb.debug_count_b);
    endtask

    task automatic check_reset_behavior();
        forever begin
            @(negedge vif.rst_n);

            #1ns
            check_reset_values("immediately after reset assertion");

            while (!vif.rst_n) begin
                @(posedge vif.clk27 or posedge vif.rst_n);

                if (vif.rst_n === 1'b0)
                    check_reset_values("while reset is held");
            end

            repeat (3) begin
                @(posedge vif.clk27);
                check_reset_values("idle after reset release");
            end
        end
    endtask

    task automatic check_reset_values(input string phase);

        if (vif.busy !== 1'b0) begin
            $fatal(1, "[%0t] %s: busy=%b, expected 0",
                $time, phase, vif.busy);
        end

        if (vif.ready !== 1'b0) begin
            $fatal(1, "[%0t] %s: ready=%b, expected 0",
                $time, phase, vif.ready);
        end

        if (vif.response !== '0) begin
            $fatal(1, "[%0t] %s: response=%h, expected 0",
                $time, phase, vif.response);
        end

        if (vif.debug_count_a !== '0) begin
            $fatal(1, "[%0t] %s: debug_count_a=%h, expected 0",
                $time, phase, vif.debug_count_a);
        end

        if (vif.debug_count_b !== '0) begin
            $fatal(1, "[%0t] %s: debug_count_b=%h, expected 0",
                $time, phase, vif.debug_count_b);
        end

    endtask

endmodule
