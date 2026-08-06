timeunit 1ns;
timeprecision 1ps;

module puf_core_if_compile_tb;

    localparam int TEST_CHALLENGE_WIDTH = 13;
    localparam int TEST_RESPONSE_BITS   = 5;
    localparam int TEST_COUNTER_WIDTH   = 17;

    logic clk27 = 1'b0;


    puf_core_if #(
        .CHALLENGE_WIDTH (TEST_CHALLENGE_WIDTH),
        .RESPONSE_BITS   (TEST_RESPONSE_BITS),
        .COUNTER_WIDTH   (TEST_COUNTER_WIDTH)
    ) puf_if (
        .clk27(clk27)
    );

    initial begin
        if ($bits(puf_if.challenge) != TEST_CHALLENGE_WIDTH)
            $fatal(1, "Incorrect challenge width");

        if ($bits(puf_if.response) != TEST_RESPONSE_BITS)
            $fatal(1, "Incorrect response width");

        if ($bits(puf_if.debug_count_a) != TEST_COUNTER_WIDTH)
            $fatal(1, "Incorrect debug_count_a width");

        if ($bits(puf_if.debug_count_b) != TEST_COUNTER_WIDTH)
            $fatal(1, "Incorrect debug_count_b width");

        if ($bits(puf_if.rst_n) != 1)
            $fatal(1, "Incorrect rst_n width");

        if ($bits(puf_if.start) != 1)
            $fatal(1, "Incorrect start width");

        if ($bits(puf_if.busy) != 1)
            $fatal(1, "Incorrect busy width");

        if ($bits(puf_if.ready) != 1)
            $fatal(1, "Incorrect ready width");

        if ($bits(puf_if.clk27) != 1)
            $fatal(1, "Incorrect clk27 width");

        $display("PUF_CORE_IF COMPILE TEST PASSED");
        $finish;
    end

endmodule
