timeunit 1ns;
timeprecision 1ps;

module puf_core_checker (
    puf_core_if.checker_mp vif
);

    localparam MAX_TEST_CYCLES = 50000;

    localparam int INDEX_WIDTH = (vif.NUM_RO <= 2) ? 1 : $clog2(vif.NUM_RO);

    typedef struct packed {
        logic [vif.RESPONSE_BITS-1:0] response;
        logic [vif.COUNTER_WIDTH-1:0] debug_count_a;
        logic [vif.COUNTER_WIDTH-1:0] debug_count_b;
    } prediction_t;

    longint signed previous_clk_tick = -1;
    longint signed clk_period_ticks = 0;

    always @(posedge vif.clk27) begin
        if (previous_clk_tick >= 0)
            clk_period_ticks = longint'($realtime / 1ps) - previous_clk_tick;
        previous_clk_tick = longint'($realtime / 1ps);
    end

    initial begin
        if (vif.PROFILE == 3) begin
            static bit busy_seen = 0;
            repeat (MAX_TEST_CYCLES) begin
                @(vif.mon_cb);

                if (vif.mon_cb.ready === 1'b1)
                    $fatal(1, "ready appeared");

                if (!busy_seen) begin
                    if (vif.mon_cb.busy === 1'b1)
                        busy_seen = 1;
                end
                else if (vif.mon_cb.busy !== 1'b1) begin
                    $fatal(1, "busy dropped");
                end
            end

            if (!busy_seen)
                $fatal(1, "busy was never asserted");

            $display("EXPECTED TIMEOUT - PASS");
            $finish;
        end else begin
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
        prediction_t                  predicted;
        logic [vif.COUNTER_WIDTH-1:0] saved_count_a;
        logic [vif.COUNTER_WIDTH-1:0] saved_count_b;
        logic                         result_hold;

        forever begin
            @(vif.mon_cb or negedge vif.rst_n);

            if (completed_count == 3) begin
                if (accepted_count != 3)
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
                            predicted = predict_responce(vif.mon_cb.challenge);
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
                                $time, vif.mon_cb.busy, vif.mon_cb.response, vif.mon_cb.debug_count_a, vif.mon_cb.debug_count_b);
                            if (vif.mon_cb.response !== predicted.response)
                                $fatal(1, "[%0t] WAIT_READY: response expected=%h actual=%h",
                                    $time, predicted.response, vif.mon_cb.response);
                            if (vif.mon_cb.debug_count_a !== predicted.debug_count_a)
                                $fatal(1, "[%0t] WAIT_READY: debug_count_a expected=%0d actual=%0d",
                                    $time, predicted.debug_count_a, vif.mon_cb.debug_count_a);
                            if (vif.mon_cb.debug_count_b !== predicted.debug_count_b)
                                $fatal(1, "[%0t] WAIT_READY: debug_count_b expected=%0d actual=%0d",
                                    $time, predicted.debug_count_b, vif.mon_cb.debug_count_b);
                            completed_count++;
                            result_hold = 1'b1;
                            saved_response = vif.mon_cb.response;
                            saved_count_a  = vif.mon_cb.debug_count_a;
                            saved_count_b  = vif.mon_cb.debug_count_b;
                            if (vif.mon_cb.start === 1'b1 && vif.mon_cb.busy === 1'b0) begin
                                state = WAIT_BUSY;
                                accepted_count++;
                                result_hold = 1'b0;
                                predicted = predict_responce(vif.mon_cb.challenge);
                            end
                            else
                                state = WAIT_START;
                        end
                    end

                    default: 
                        state = WAIT_START;
                endcase
            end
        end

    endtask: check_normal_protocol

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

    // RO model starts low at t=0 and rises at H, 3H, 5H, ... .
    // A gate/toggle changed by NBA is sampled only on a STRICTLY later edge.
    function automatic longint signed next_ro_edge(
        input longint signed tick,
        input longint signed half_period
    );
        if (tick < half_period)
            return half_period;
        return half_period + ((tick - half_period) / (2 * half_period) + 1)
                           * (2 * half_period);
    endfunction: next_ro_edge

    // Call on the clk27 edge accepting start. This predicts the deterministic
    // ro_array_sim_model (constant periods, common t=0 origin, no jitter), using
    // only challenge, model parameters and clock timing, never DUT results.
    function automatic prediction_t predict_responce(
        input logic [vif.CHALLENGE_WIDTH-1:0] challenge
    );
        prediction_t result;
        logic [vif.CHALLENGE_WIDTH-1:0] offset_challenge;
        int unsigned a, b;
        longint signed gate_open, gate_close;
        longint signed half_a, half_b;
        longint signed rise_a, rise_b, fall_a, fall_b;
        longint signed snapshot_a, snapshot_b, last_snapshot, pair_done_tick;

        if ($isunknown(challenge) || vif.NUM_RO < 2 ||
            vif.CHALLENGE_WIDTH < 2 * INDEX_WIDTH ||
            vif.WINDOW_CYCLES < 1 || clk_period_ticks <= 0)
            $fatal(1, "predict_responce: invalid challenge, parameters or clock period");

        result = '0;
        // Accept start -> clear -> settle -> pair_start accepted by timer.
        gate_open = longint'($realtime / 1ps)
                  + (longint'(vif.RO_SETTLE_CYCLES) + 2) * clk_period_ticks;

        for (int i = 0; i < vif.RESPONSE_BITS; i++) begin
            offset_challenge = challenge + i;
            a = offset_challenge[INDEX_WIDTH-1:0] % vif.NUM_RO;
            b = offset_challenge[2*INDEX_WIDTH-1:INDEX_WIDTH] % vif.NUM_RO;
            if (a == b)
                b = (b + 1) % vif.NUM_RO;

            half_a = longint'(vif.HALF_PERIODS[a] / 1ps);
            half_b = longint'(vif.HALF_PERIODS[b] / 1ps);
            if (!vif.ENABLED[a] || !vif.ENABLED[b] || half_a <= 0 || half_b <= 0)
                $fatal(1, "predict_responce: bit %0d selects a stopped/invalid RO (%0d,%0d)", i, a, b);

            gate_close = gate_open + longint'(vif.WINDOW_CYCLES) * clk_period_ticks;
            rise_a = next_ro_edge(gate_open, half_a);
            rise_b = next_ro_edge(gate_open, half_b);
            fall_a = next_ro_edge(gate_close, half_a);
            fall_b = next_ro_edge(gate_close, half_b);
            if (fall_a == rise_a || fall_b == rise_b)
                $fatal(1, "predict_responce: bit %0d has an unsampled measurement window", i);

            // Synchronizers delay both boundaries equally. Clear consumes the
            // first enabled edge, leaving N-1 increments. Assignment truncates
            // to COUNTER_WIDTH, matching hardware counter wraparound.
            result.debug_count_a = (fall_a - rise_a) / (2 * half_a) - 1;
            result.debug_count_b = (fall_b - rise_b) / (2 * half_b) - 1;
            result.response[i] = (result.debug_count_a > result.debug_count_b);

            // Snapshot/toggle occurs two RO periods after gate-low is sampled.
            snapshot_a = fall_a + 4 * half_a;
            snapshot_b = fall_b + 4 * half_b;
            last_snapshot = (snapshot_a > snapshot_b) ? snapshot_a : snapshot_b;
            // First later clk27 samples toggle, next synchronizes it, next
            // asserts pair_done. FSM then waits/stores/settles/starts again.
            pair_done_tick = gate_open
                           + ((last_snapshot - gate_open) / clk_period_ticks + 3)
                           * clk_period_ticks;
            gate_open = pair_done_tick
                      + (longint'(vif.RO_SETTLE_CYCLES) + 3) * clk_period_ticks;
        end

        return result;
    endfunction: predict_responce

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
        end
    endtask: check_reset_behavior

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

    endtask: check_reset_values

endmodule: puf_core_checker
