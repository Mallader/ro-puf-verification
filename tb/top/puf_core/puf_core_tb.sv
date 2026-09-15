timeunit 1ns;
timeprecision 1ps;

module puf_core_tb #(
    parameter int PROFILE    = 0
    );

    localparam int NUM_RO                = 4;
    localparam int PROFILE_NORMAL        = 0;
    localparam int PROFILE_TIE_LAST      = 1;
    localparam int PROFILE_CLOSE         = 2;
    localparam int PROFILE_STOPPED       = 3;
    localparam int PROFILE_EXTREME       = 4;
    localparam int WINDOW_CYCLES         = 100;
    localparam int TEST_CHALLENGE_WIDTH  = 10;
    localparam int TEST_RESPONSE_BITS    = 10;
    localparam int TEST_COUNTER_WIDTH    = 16;
    localparam int TEST_RO_SETTLE_CYCLES = 16;

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

    puf_core_if #(
        .NUM_RO          (NUM_RO),
        .RESPONSE_BITS   (TEST_RESPONSE_BITS),
        .COUNTER_WIDTH   (TEST_COUNTER_WIDTH),
        .WINDOW_CYCLES   (WINDOW_CYCLES),
        .RO_SETTLE_CYCLES(TEST_RO_SETTLE_CYCLES),
        .CHALLENGE_WIDTH (TEST_CHALLENGE_WIDTH),
        .HALF_PERIODS    (HALF_PERIODS),
        .ENABLED         (ENABLED),
        .PROFILE         (PROFILE)
     ) puf_core_if (
        .clk27(clk27)
    );

    puf_core_dut_wrapper puf_core_dut_wrapper (
        .vif(puf_core_if)
    );

    puf_core_driver puf_core_driver (
        .vif(puf_core_if)
    );

    puf_core_monitor puf_core_monitor (
        .vif(puf_core_if)
    );

    puf_core_checker puf_core_checker (
        .vif(puf_core_if)
    );

endmodule: puf_core_tb
