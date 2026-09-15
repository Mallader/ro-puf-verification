timeunit 1ns;
timeprecision 1ps;

module puf_core_dut_wrapper (
    puf_core_if.dut_mp vif
);

    puf_core #(
        .NUM_RO          (vif.NUM_RO),
        .RESPONSE_BITS   (vif.RESPONSE_BITS),
        .COUNTER_WIDTH   (vif.COUNTER_WIDTH),
        .WINDOW_CYCLES   (vif.WINDOW_CYCLES),
        .RO_SETTLE_CYCLES(vif.RO_SETTLE_CYCLES),
        .CHALLENGE_WIDTH (vif.CHALLENGE_WIDTH),
        .HALF_PERIODS    (vif.HALF_PERIODS),
        .ENABLED         (vif.ENABLED)
     ) puf_core (
        .clk27        (vif.clk27),
        .rst_n        (vif.rst_n),
        .start        (vif.start),
        .challenge    (vif.challenge),
        .busy         (vif.busy),
        .ready        (vif.ready),
        .response     (vif.response),
        .debug_count_a(vif.debug_count_a),
        .debug_count_b(vif.debug_count_b)
    );

endmodule: puf_core_dut_wrapper
