timeunit 1ns;
timeprecision 1ps;

module ro_array_sim_model #(
    parameter int NUM_RO = 4,
    parameter realtime HALF_PERIODS [0:NUM_RO-1]= '{default:5ns}
)(
    output wire [NUM_RO-1:0] ro_clk
);

    genvar i;

    generate
        for (i = 0; i < NUM_RO; i = i + 1) begin : gen_ro

            ring_oscillator #(.HALF_PERIOD(HALF_PERIODS[i])) u_ring_oscillator (
                .ro_clk (ro_clk[i])
            );

        end
    endgenerate

endmodule

module ring_oscillator #(
    parameter realtime HALF_PERIOD = 5ns
)(
    output logic ro_clk
);

    initial begin
        ro_clk = 1'b0;

        forever begin
            #(HALF_PERIOD);
            ro_clk = ~ro_clk;
        end
    end

endmodule
