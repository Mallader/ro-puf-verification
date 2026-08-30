timeunit 1ns;
timeprecision 1ps;

module dut_wrapper (
    ro_pair_measure_if.dut_mp vif
);

    logic [vif.NUM_RO-1:0] ro_clk;
    logic ro_clk_a, ro_clk_b;

    assign ro_clk_a = ro_clk[vif.RO_A_INDEX];
    assign ro_clk_b = ro_clk[vif.RO_B_INDEX]; 

    ro_pair_measure #(
        .COUNTER_WIDTH(vif.COUNTER_WIDTH),
        .WINDOW_CYCLES(vif.WINDOW_CYCLES)
     ) ro_pair_measure (
        .clk27   (vif.clk27),
        .rst_n   (vif.rst_n),
        .start   (vif.start),
        .ro_clk_a(ro_clk_a),
        .ro_clk_b(ro_clk_b),
        .busy    (vif.busy),
        .done    (vif.done),
        .puf_bit (vif.puf_bit),
        .tie     (vif.tie),
        .count_a (vif.count_a),
        .count_b (vif.count_b)
    );

    ro_array_sim_model #(
        .NUM_RO      (vif.NUM_RO),
        .HALF_PERIODS(vif.HALF_PERIODS)
     ) ro_array_sim_model (
        .ro_clk(ro_clk)
    );

endmodule
