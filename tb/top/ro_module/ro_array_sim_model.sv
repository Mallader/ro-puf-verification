timeunit 1ns;
timeprecision 1ps;

module ro_array_sim_model #(
    parameter int NUM_RO = 4
)(
    output wire [NUM_RO-1:0] ro_clk
);

    localparam time half_periods [0:NUM_RO-1]= '{4, 5, 6, 7};

    genvar i;

    generate
        for (i = 0; i < NUM_RO; i = i + 1) begin : gen_ro

            ring_oscillator #(.half_period(half_periods[i])) u_ring_oscillator (
                .ro_clk (ro_clk[i])
            );

        end
    endgenerate

endmodule

module ring_oscillator #(
    parameter time half_period = 5
)(
    output logic ro_clk
);

    initial begin
        ro_clk = 1'b0;

        forever begin
            #(half_period);
            ro_clk = ~ro_clk;
        end
    end

endmodule
