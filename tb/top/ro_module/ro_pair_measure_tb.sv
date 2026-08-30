timeunit 1ns;
timeprecision 1ps;

module ro_pair_measure_tb #(parameter int PROFILE = 0);

    localparam int NUM_RO           = 4;
    localparam int PROFILE_NORMAL   = 0;
    localparam int PROFILE_TIE_LAST = 1;
    localparam int PROFILE_CLOSE    = 2;
    localparam int COUNTER_WIDTH    = 16;
    localparam int WINDOW_CYCLES    = 100;

    localparam realtime HALF_PERIODS [NUM_RO] =
        (PROFILE == PROFILE_NORMAL)   ? '{4ns, 5ns, 6ns, 7ns}   :
        (PROFILE == PROFILE_TIE_LAST) ? '{4ns, 5ns, 7ns, 7ns}   :
        (PROFILE == PROFILE_CLOSE)    ? '{4ns, 5ns, 6.2ns, 6.0ns} :
                                        '{4ns, 5ns, 6ns, 7ns};

    logic clk27 = 1'b0;

    always #5 clk27 = ~clk27;

    ro_pair_measure_if #(
        .NUM_RO          (NUM_RO),
        .PROFILE_NORMAL  (PROFILE_NORMAL),
        .PROFILE_TIE_LAST(PROFILE_TIE_LAST),
        .PROFILE_CLOSE   (PROFILE_CLOSE),
        .COUNTER_WIDTH   (COUNTER_WIDTH),
        .WINDOW_CYCLES   (WINDOW_CYCLES),
        .HALF_PERIODS    (HALF_PERIODS),
        .RO_A_INDEX      (NUM_RO - 1),
        .RO_B_INDEX      (NUM_RO - 2)
     ) ro_pair_measure_if (
        .clk27(clk27)
    );

    dut_wrapper dut_wrapper (
        .vif(ro_pair_measure_if)
    );

    ro_module_driver ro_driver (
        .vif(ro_pair_measure_if)
    );

    ro_module_checker #(
        .PROFILE (PROFILE)
    ) ro_checker (
        .vif(ro_pair_measure_if)
    );


endmodule
