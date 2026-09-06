timeunit 1ns;
timeprecision 1ps;

module ro_pair_measure_tb #(
    parameter int PROFILE    = 0,
    parameter int RO_A_INDEX = 3,
    parameter int RO_B_INDEX = 2
    );

    localparam int NUM_RO           = 4;
    localparam int PROFILE_NORMAL   = 0;
    localparam int PROFILE_TIE_LAST = 1;
    localparam int PROFILE_CLOSE    = 2;
    localparam int PROFILE_STOPPED  = 3;
    localparam int PROFILE_EXTREME  = 4;
    localparam int COUNTER_WIDTH    = 16;
    localparam int WINDOW_CYCLES    = 100;

    localparam realtime HALF_PERIODS [NUM_RO] =
        (PROFILE == PROFILE_NORMAL)   ? '{4ns, 5ns, 6ns, 7ns}     :
        (PROFILE == PROFILE_TIE_LAST) ? '{4ns, 5ns, 7ns, 7ns}     :
        (PROFILE == PROFILE_EXTREME)  ? '{4ns, 5ns, 20ns, 2ns}    :
        (PROFILE == PROFILE_CLOSE)    ? '{4ns, 5ns, 6.2ns, 6.0ns} :
                                        '{4ns, 5ns, 6ns, 7ns};

    localparam bit ENABLED [NUM_RO] =
        (PROFILE == PROFILE_STOPPED) ? '{1'b1, 1'b1, 1'b1, 1'b0} :
                                       '{1'b1, 1'b1, 1'b1, 1'b1};

    logic clk27 = 1'b0;

    always #5 clk27 = ~clk27;

    initial begin
        if (PROFILE == PROFILE_NORMAL)
            $display("RO PROFILE: NORMAL");
        else if (PROFILE == PROFILE_TIE_LAST)
            $display("RO PROFILE: TIE_LAST");
        else if (PROFILE == PROFILE_CLOSE)
            $display("RO PROFILE: CLOSE");
        else if (PROFILE == PROFILE_STOPPED)
            $display("RO PROFILE: STOPPED");
        else if (PROFILE == PROFILE_EXTREME)
            $display("RO PROFILE: EXTREME");
        else
            $fatal(1, "Unsupported RO PROFILE: %0d", PROFILE);
    end

    ro_pair_measure_if #(
        .NUM_RO          (NUM_RO),
        .COUNTER_WIDTH   (COUNTER_WIDTH),
        .WINDOW_CYCLES   (WINDOW_CYCLES),
        .HALF_PERIODS    (HALF_PERIODS),
        .ENABLED         (ENABLED),
        .RO_A_INDEX      (RO_A_INDEX),
        .RO_B_INDEX      (RO_B_INDEX)
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


endmodule: ro_pair_measure_tb
