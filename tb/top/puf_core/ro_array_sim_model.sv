timeunit 1ns;
timeprecision 1ps;

module ro_array_sim_model #(
    parameter int      NUM_RO                    = 4,
    parameter realtime HALF_PERIODS [0:NUM_RO-1] = '{default:5ns},
    parameter bit      ENABLED [0:NUM_RO-1]      = '{default:1'b1}
)(
    output wire [NUM_RO-1:0] ro_clk
);

    genvar i;

    generate
        for (i = 0; i < NUM_RO; i = i + 1) begin : gen_ro

            ring_oscillator #(.HALF_PERIOD(HALF_PERIODS[i]), .ENABLED(ENABLED[i])) u_ring_oscillator (
                .ro_clk (ro_clk[i])
            );

        end
    endgenerate

endmodule: ro_array_sim_model

module ring_oscillator #(
    parameter realtime HALF_PERIOD = 5ns,
    parameter bit      ENABLED     = 1'b1
)(
    output logic ro_clk
);

    initial begin
        ro_clk = 1'b0;

        if (ENABLED === 1'b1)
            forever begin
                #(HALF_PERIOD);
                ro_clk = ~ro_clk;
            end
    end

endmodule: ring_oscillator
