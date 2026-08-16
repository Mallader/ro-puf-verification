module ro_array #(
    parameter integer NUM_RO = 8
)(
    output wire [NUM_RO-1:0] ro_clk
);

    /*
     * Промежуточный вектор выходов RO.
     *
     * KEEP и DONT_TOUCH используются для предотвращения удаления
     * или объединения одинаковых кольцевых генераторов синтезатором.
     */
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
    wire [NUM_RO-1:0] ro_clk_internal;

    genvar i;

    generate
        for (i = 0; i < NUM_RO; i = i + 1) begin : gen_ro

            /*
             * Каждый экземпляр должен оставаться отдельным физическим
             * кольцевым генератором.
             */
            (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
            ring_oscillator u_ring_oscillator (
                .ro_clk (ro_clk_internal[i])
            );

        end
    endgenerate

    assign ro_clk = ro_clk_internal;

endmodule

