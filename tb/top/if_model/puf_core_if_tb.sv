timeunit 1ns;
timeprecision 1ps;

module puf_core_if_modport_tb;

    localparam int TEST_CHALLENGE_WIDTH = 10;
    localparam int TEST_RESPONSE_BITS   = 10;
    localparam int TEST_COUNTER_WIDTH   = 10;

    logic clk27 = 1'b0;

    always #5 clk27 = ~clk27;


    puf_core_if #(
        .CHALLENGE_WIDTH (TEST_CHALLENGE_WIDTH),
        .RESPONSE_BITS   (TEST_RESPONSE_BITS),
        .COUNTER_WIDTH   (TEST_COUNTER_WIDTH)
    ) puf_if (
        .clk27(clk27)
    );

    puf_core_model dut_model (
        .vif(puf_if)
    );

    puf_driver_probe puf_driver (
        .vif(puf_if)
    );

    puf_monitor_probe puf_monitor (
        .vif(puf_if)
    );

    puf_checker_probe puf_checker (
        .vif(puf_if)
    );

endmodule
