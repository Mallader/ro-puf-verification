module ro_counter #(
    parameter integer WIDTH = 32
) (
    input  logic                 ro_clk,
    input  logic                 rst_n,
    input  logic                 clear,
    input  logic                 enable,

    output logic [WIDTH-1:0]     count
);

    always_ff @(posedge ro_clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else if (clear) begin
            count <= '0;
        end else if (enable) begin
            count <= count + 1'b1;
        end
    end

endmodule