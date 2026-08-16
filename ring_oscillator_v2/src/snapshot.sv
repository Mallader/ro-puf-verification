module snapshot #(
    parameter integer WIDTH = 32
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 capture,
    input  logic [WIDTH-1:0]     data_in,

    output logic [WIDTH-1:0]     data_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= '0;
        end else if (capture) begin
            data_out <= data_in;
        end
    end

endmodule