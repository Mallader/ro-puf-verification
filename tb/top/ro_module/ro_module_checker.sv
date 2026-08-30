timeunit 1ns;
timeprecision 1ps;

module ro_module_checker #(
    parameter int PROFILE = 1
) (
    ro_pair_measure_if.checker_mp vif
);

    localparam int MAX_TEST_CYCLES = 200;

    initial begin
        if (PROFILE == vif.PROFILE_NORMAL)
            $display("RO PROFILE: NORMAL");
        else if (PROFILE == vif.PROFILE_TIE_LAST)
            $display("RO PROFILE: TIE_LAST");
        else if (PROFILE == vif.PROFILE_CLOSE)
            $display("RO PROFILE: CLOSE");
        else
            $fatal(1, "Unsupported RO PROFILE: %0d", PROFILE);
    end
    
    initial begin
        fork
            measure_and_check(vif.RO_A_INDEX, vif.RO_B_INDEX);
            begin
                repeat (MAX_TEST_CYCLES) @(posedge vif.clk27);
                $fatal(1, "TEST TIMEOUT");
            end
        join_any

        disable fork;
    end

    task automatic measure_and_check (int ro_a_index, int ro_b_index);

        bit observed_count_relation;
        bit observed_tie;
        bit predicted_result;
        bit predicted_tie;
        predict_pair(
            ro_a_index,
            ro_b_index,
            predicted_result,
            predicted_tie
        );

        forever begin
            @(vif.mon_cb)
            if (vif.mon_cb.done === 1'b1) begin
                if ($isunknown({vif.mon_cb.count_a, vif.mon_cb.count_b, vif.mon_cb.puf_bit, vif.mon_cb.tie}))
                    $fatal(1, "DUT result contains X/Z");

                if (vif.mon_cb.count_a > vif.mon_cb.count_b)
                    observed_count_relation = 1;
                else
                    observed_count_relation = 0;
                
                if (vif.mon_cb.count_a === vif.mon_cb.count_b)
                    observed_tie = 1;
                else
                    observed_tie = 0;

                if ((predicted_result !== observed_count_relation) || (predicted_result !== vif.mon_cb.puf_bit) ||
                    (predicted_tie !== vif.mon_cb.tie) || (predicted_tie !== observed_tie))
                    $fatal(1, "pair RO%0d and RO%0d: observed_count_relation = %0d, predicted_result = %0d, puf_bit = %0d, tie = %0d", 
                           ro_a_index, ro_b_index, observed_count_relation, predicted_result, vif.mon_cb.puf_bit, vif.mon_cb.tie);

                $display("pair RO%0d and RO%0d: result = %0d, PASS", ro_a_index, ro_b_index, predicted_result);
                $finish;
            end
        end

    endtask: measure_and_check

    function automatic void predict_pair (int ro_a_index, int ro_b_index, output bit predicted_result, output bit predicted_tie);
        if ((0 > ro_a_index) || (ro_a_index >= vif.NUM_RO) ||
            (0 > ro_b_index) || (ro_b_index >= vif.NUM_RO))
            $fatal (1, "RO index out of range: a=%0d, b=%0d, valid range=0..%0d",
                    ro_a_index, ro_b_index, vif.NUM_RO-1);

        if (ro_a_index == ro_b_index)
            $fatal(1, "RO cannot be compared with itself: RO%0d", ro_a_index);
        
        predicted_tie    = (vif.HALF_PERIODS[ro_a_index] == vif.HALF_PERIODS[ro_b_index]);
        predicted_result = (vif.HALF_PERIODS[ro_a_index] < vif.HALF_PERIODS[ro_b_index]);
    endfunction

endmodule
