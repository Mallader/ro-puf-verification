module ring_oscillator(
    output wire ro_clk
);

    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
    wire n0, n1, n2;

    LUT4 #(
        .INIT(16'h5555)      // NOT
    ) lut0 (
        .F(n0),
        .I0(n2),
        .I1(1'b0),
        .I2(1'b0),
        .I3(1'b0)
    );

    LUT4 #(
        .INIT(16'h5555)
    ) lut1 (
        .F(n1),
        .I0(n0),
        .I1(1'b0),
        .I2(1'b0),
        .I3(1'b0)
    );

    LUT4 #(
        .INIT(16'h5555)
    ) lut2 (
        .F(n2),
        .I0(n1),
        .I1(1'b0),
        .I2(1'b0),
        .I3(1'b0)
    );

    assign ro_clk = n2;

endmodule