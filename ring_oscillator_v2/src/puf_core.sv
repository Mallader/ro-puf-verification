module puf_core #(
    parameter integer NUM_RO           = 8,
    parameter integer RESPONSE_BITS    = 16,
    parameter integer COUNTER_WIDTH    = 32,
    parameter integer WINDOW_CYCLES    = 270_000,
    parameter integer RO_SETTLE_CYCLES = 16,
    parameter integer CHALLENGE_WIDTH  = 32
) (
    input  wire                         clk27,
    input  wire                         rst_n,

    // Однотактный импульс запуска в домене clk27.
    // Во время busy новые команды start игнорируются.
    input  wire                         start,

    // Базовый challenge для формирования последовательности пар RO.
    input  wire [CHALLENGE_WIDTH-1:0]   challenge,

    // Состояние PUF.
    output wire                         busy,
    output logic                        ready,

    // Готовый многобитный PUF-response.
    output wire [RESPONSE_BITS-1:0]     response,

    // Счётчики последней измеренной пары.
    output wire [COUNTER_WIDTH-1:0]     debug_count_a,
    output wire [COUNTER_WIDTH-1:0]     debug_count_b
);

    localparam integer INDEX_WIDTH =
        (NUM_RO <= 2) ? 1 : $clog2(NUM_RO);

    localparam integer BIT_INDEX_WIDTH =
        (RESPONSE_BITS <= 1) ? 1 : $clog2(RESPONSE_BITS);

    localparam integer PAIR_CHALLENGE_WIDTH =
        2 * INDEX_WIDTH;


    // -------------------------------------------------------------------------
    // Зафиксированный challenge
    // -------------------------------------------------------------------------

    logic [CHALLENGE_WIDTH-1:0] challenge_latched;


    // -------------------------------------------------------------------------
    // Массив Ring Oscillator
    // -------------------------------------------------------------------------

    wire [NUM_RO-1:0] ro_clks;


    // -------------------------------------------------------------------------
    // Текущий бит response и challenge для выбранной пары
    // -------------------------------------------------------------------------

    wire [BIT_INDEX_WIDTH-1:0] bit_index;

    wire [CHALLENGE_WIDTH-1:0] challenge_with_offset;

    wire [PAIR_CHALLENGE_WIDTH-1:0] pair_challenge;


    // Для response-бита с номером bit_index используется:
    //
    //     pair_challenge = challenge_latched + bit_index
    //
    // challenge_mapper использует младшие 2*INDEX_WIDTH бит.
    assign challenge_with_offset =
        challenge_latched + bit_index;

    assign pair_challenge =
        challenge_with_offset[PAIR_CHALLENGE_WIDTH-1:0];


    // -------------------------------------------------------------------------
    // Выбор пары RO
    // -------------------------------------------------------------------------

    wire [INDEX_WIDTH-1:0] ro_index_a;
    wire [INDEX_WIDTH-1:0] ro_index_b;

    wire ro_clk_a;
    wire ro_clk_b;

    assign ro_clk_a = ro_clks[ro_index_a];
    assign ro_clk_b = ro_clks[ro_index_b];


    // -------------------------------------------------------------------------
    // Интерфейс одного измерения пары RO
    // -------------------------------------------------------------------------

    wire pair_start;
    wire pair_measure_busy;
    wire pair_done;

    wire pair_puf_bit;
    wire pair_tie;

    wire response_bit;

    wire [COUNTER_WIDTH-1:0] pair_count_a;
    wire [COUNTER_WIDTH-1:0] pair_count_b;


    // При равенстве счётчиков сохраняется 0.
    // Это совпадает с поведением ro_pair_measure.
    assign response_bit =
        pair_tie ? 1'b0 : pair_puf_bit;


    // -------------------------------------------------------------------------
    // Управление формированием response
    // -------------------------------------------------------------------------

    wire response_clear;
    wire response_store;

    wire sequence_done;


    // -------------------------------------------------------------------------
    // Фиксация challenge и формирование ready
    // -------------------------------------------------------------------------

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            challenge_latched <= '0;
            ready             <= 1'b0;
        end else begin

            // Команда принимается только тогда, когда PUF свободен.
            if (start && !busy) begin
                challenge_latched <= challenge;
                ready             <= 1'b0;
            end else if (sequence_done) begin
                ready <= 1'b1;
            end
        end
    end


    // -------------------------------------------------------------------------
    // Массив кольцевых генераторов
    // -------------------------------------------------------------------------

    ro_array #(
        .NUM_RO (NUM_RO)
    ) u_ro_array (
        .ro_clk (ro_clks)
    );


    // -------------------------------------------------------------------------
    // Преобразование challenge в два разных индекса RO
    // -------------------------------------------------------------------------

    challenge_mapper #(
        .NUM_RO      (NUM_RO),
        .INDEX_WIDTH (INDEX_WIDTH)
    ) u_challenge_mapper (
        .challenge  (pair_challenge),
        .ro_index_a (ro_index_a),
        .ro_index_b (ro_index_b)
    );


    // -------------------------------------------------------------------------
    // Измерение выбранной пары RO
    // -------------------------------------------------------------------------

    ro_pair_measure #(
        .COUNTER_WIDTH (COUNTER_WIDTH),
        .WINDOW_CYCLES (WINDOW_CYCLES)
    ) u_ro_pair_measure (
        .clk27    (clk27),
        .rst_n    (rst_n),

        .start    (pair_start),

        .ro_clk_a (ro_clk_a),
        .ro_clk_b (ro_clk_b),

        .busy     (pair_measure_busy),
        .done     (pair_done),

        .puf_bit  (pair_puf_bit),
        .tie      (pair_tie),

        .count_a  (pair_count_a),
        .count_b  (pair_count_b)
    );


    // -------------------------------------------------------------------------
    // Управляющий автомат
    // -------------------------------------------------------------------------

    puf_fsm #(
        .RESPONSE_BITS    (RESPONSE_BITS),
        .BIT_INDEX_WIDTH  (BIT_INDEX_WIDTH),
        .RO_SETTLE_CYCLES (RO_SETTLE_CYCLES)
    ) u_puf_fsm (
        .clk27          (clk27),
        .rst_n          (rst_n),

        .start          (start),
        .pair_done      (pair_done),

        .busy           (busy),
        .done           (sequence_done),

        .pair_start     (pair_start),

        .response_clear (response_clear),
        .response_store (response_store),

        .bit_index      (bit_index)
    );


    // -------------------------------------------------------------------------
    // Сборка многобитного response
    // -------------------------------------------------------------------------

    response_builder #(
        .RESPONSE_BITS   (RESPONSE_BITS),
        .COUNTER_WIDTH   (COUNTER_WIDTH),
        .BIT_INDEX_WIDTH (BIT_INDEX_WIDTH)
    ) u_response_builder (
        .clk27         (clk27),
        .rst_n         (rst_n),

        .clear         (response_clear),
        .store         (response_store),

        .bit_index     (bit_index),
        .puf_bit       (response_bit),

        .count_a       (pair_count_a),
        .count_b       (pair_count_b),

        .response      (response),

        .debug_count_a (debug_count_a),
        .debug_count_b (debug_count_b)
    );

endmodule