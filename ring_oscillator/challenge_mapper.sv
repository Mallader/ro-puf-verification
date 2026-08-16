module challenge_mapper #(
    parameter integer NUM_RO = 8,

    // Для NUM_RO = 8 ширина индекса равна 3 битам.
    parameter integer INDEX_WIDTH =
        (NUM_RO <= 2) ? 1 : $clog2(NUM_RO)
)(
    input  wire [2*INDEX_WIDTH-1:0] challenge,

    output logic [INDEX_WIDTH-1:0] ro_index_a,
    output logic [INDEX_WIDTH-1:0] ro_index_b
);

    /*
     * Временные переменные используются для приведения значений
     * challenge к допустимому диапазону 0 ... NUM_RO-1.
     */
    integer index_a_tmp;
    integer index_b_tmp;

    always_comb begin
        /*
         * Младшая половина challenge задаёт первый RO,
         * старшая половина — второй RO.
         *
         * Операция остатка нужна для поддержки NUM_RO,
         * не являющегося степенью двойки.
         * При NUM_RO = 8 синтезатор упростит эту логику.
         */
        index_a_tmp = challenge[INDEX_WIDTH-1:0] %
                      NUM_RO;

        index_b_tmp = challenge[2*INDEX_WIDTH-1:INDEX_WIDTH] %
                      NUM_RO;

        /*
         * Нельзя сравнивать генератор сам с собой.
         * При совпадении выбираем следующий RO.
         */
        if (index_b_tmp == index_a_tmp) begin
            if (index_b_tmp == (NUM_RO - 1))
                index_b_tmp = 0;
            else
                index_b_tmp = index_b_tmp + 1;
        end

        ro_index_a = index_a_tmp[INDEX_WIDTH-1:0];
        ro_index_b = index_b_tmp[INDEX_WIDTH-1:0];
    end

endmodule