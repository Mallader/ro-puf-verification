module response_builder #(
    parameter integer RESPONSE_BITS = 16,
    parameter integer COUNTER_WIDTH = 32,

    parameter integer BIT_INDEX_WIDTH =
        (RESPONSE_BITS <= 1) ? 1 : $clog2(RESPONSE_BITS)
) (
    input  logic                         clk27,
    input  logic                         rst_n,

    // Управление от puf_fsm.
    input  logic                         clear,
    input  logic                         store,

    // Номер сохраняемого response-бита.
    input  logic [BIT_INDEX_WIDTH-1:0]   bit_index,

    // Результат сравнения текущей пары RO.
    input  logic                         puf_bit,

    // Raw counters текущей измеренной пары.
    input  logic [COUNTER_WIDTH-1:0]     count_a,
    input  logic [COUNTER_WIDTH-1:0]     count_b,

    // Собранный многобитный PUF-response.
    output logic [RESPONSE_BITS-1:0]     response,

    // Raw counters последней сохранённой пары.
    output logic [COUNTER_WIDTH-1:0]     debug_count_a,
    output logic [COUNTER_WIDTH-1:0]     debug_count_b
);

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            response      <= '0;
            debug_count_a <= '0;
            debug_count_b <= '0;
        end else if (clear) begin
            /*
             * Начало формирования нового response.
             *
             * Clear имеет приоритет над store.
             */
            response      <= '0;
            debug_count_a <= '0;
            debug_count_b <= '0;
        end else if (store) begin
            /*
             * Сохраняется только один текущий бит.
             * Остальные ранее записанные биты не изменяются.
             */
            response[bit_index] <= puf_bit;

            /*
             * Debug-регистры всегда содержат счётчики
             * последней сохранённой пары RO.
             */
            debug_count_a <= count_a;
            debug_count_b <= count_b;
        end
    end

endmodule