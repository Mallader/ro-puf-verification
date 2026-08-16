module puf_fsm #(
    parameter integer RESPONSE_BITS = 16,

    parameter integer BIT_INDEX_WIDTH =
        (RESPONSE_BITS <= 1) ? 1 : $clog2(RESPONSE_BITS),

    parameter integer RO_SETTLE_CYCLES = 16
) (
    input  logic                         clk27,
    input  logic                         rst_n,

    // Запуск формирования полного PUF-response.
    // Принимается только в состоянии IDLE.
    input  logic                         start,

    // Однотактный сигнал завершения измерения текущей пары.
    input  logic                         pair_done,

    // Общий статус последовательности измерений.
    output logic                         busy,
    output logic                         done,

    // Однотактный запуск ro_pair_measure.
    output logic                         pair_start,

    // Управление response_builder.
    output logic                         response_clear,
    output logic                         response_store,

    // Номер формируемого response-бита.
    output logic [BIT_INDEX_WIDTH-1:0]   bit_index
);

    /*
     * Ширина счётчика паузы после переключения пары RO.
     */
    localparam integer SETTLE_COUNT_WIDTH =
        (RO_SETTLE_CYCLES <= 1) ?
        1 :
        $clog2(RO_SETTLE_CYCLES);

    /*
     * Индекс последнего формируемого response-бита.
     */
    localparam logic [BIT_INDEX_WIDTH-1:0] LAST_BIT_INDEX =
        RESPONSE_BITS - 1;

    /*
     * Последнее значение счётчика паузы.
     *
     * Отдельная обработка RO_SETTLE_CYCLES <= 1 предотвращает
     * отрицательные значения и нулевую ширину вектора.
     */
    localparam logic [SETTLE_COUNT_WIDTH-1:0] SETTLE_LAST_COUNT =
        (RO_SETTLE_CYCLES <= 1) ?
        '0 :
        RO_SETTLE_CYCLES - 1;


    // -------------------------------------------------------------------------
    // Состояния автомата
    // -------------------------------------------------------------------------

    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_CLEAR_RESPONSE,
        STATE_SETTLE,
        STATE_START_PAIR,
        STATE_WAIT_PAIR,
        STATE_STORE_RESULT,
        STATE_DONE
    } state_t;

    state_t state;
    state_t next_state;


    // -------------------------------------------------------------------------
    // Счётчик времени стабилизации выбранной пары RO
    // -------------------------------------------------------------------------

    logic [SETTLE_COUNT_WIDTH-1:0] settle_count;


    // -------------------------------------------------------------------------
    // Логика переходов
    // -------------------------------------------------------------------------

    always_comb begin
        next_state = state;

        case (state)

            /*
             * Ожидание команды запуска.
             */
            STATE_IDLE: begin
                if (start)
                    next_state = STATE_CLEAR_RESPONSE;
            end


            /*
             * Очистка response перед новой последовательностью.
             */
            STATE_CLEAR_RESPONSE: begin
                if (RO_SETTLE_CYCLES == 0)
                    next_state = STATE_START_PAIR;
                else
                    next_state = STATE_SETTLE;
            end


            /*
             * Пауза после изменения challenge и выбора новой пары RO.
             */
            STATE_SETTLE: begin
                if (settle_count == SETTLE_LAST_COUNT)
                    next_state = STATE_START_PAIR;
            end


            /*
             * Формирование однотактного pair_start.
             */
            STATE_START_PAIR: begin
                next_state = STATE_WAIT_PAIR;
            end


            /*
             * Ожидание окончания измерения текущей пары.
             */
            STATE_WAIT_PAIR: begin
                if (pair_done)
                    next_state = STATE_STORE_RESULT;
            end


            /*
             * Сохранение результата текущей пары.
             */
            STATE_STORE_RESULT: begin
                if (bit_index == LAST_BIT_INDEX) begin
                    next_state = STATE_DONE;
                end else if (RO_SETTLE_CYCLES == 0) begin
                    next_state = STATE_START_PAIR;
                end else begin
                    next_state = STATE_SETTLE;
                end
            end


            /*
             * Полный response сформирован.
             */
            STATE_DONE: begin
                next_state = STATE_IDLE;
            end


            default: begin
                next_state = STATE_IDLE;
            end

        endcase
    end


    // -------------------------------------------------------------------------
    // Выходные сигналы автомата
    // -------------------------------------------------------------------------

    always_comb begin
        busy           = 1'b0;
        done           = 1'b0;
        pair_start     = 1'b0;
        response_clear = 1'b0;
        response_store = 1'b0;

        case (state)

            STATE_IDLE: begin
                busy = 1'b0;
            end


            STATE_CLEAR_RESPONSE: begin
                busy           = 1'b1;
                response_clear = 1'b1;
            end


            STATE_SETTLE: begin
                busy = 1'b1;
            end


            STATE_START_PAIR: begin
                busy       = 1'b1;
                pair_start = 1'b1;
            end


            STATE_WAIT_PAIR: begin
                busy = 1'b1;
            end


            STATE_STORE_RESULT: begin
                busy           = 1'b1;
                response_store = 1'b1;
            end


            STATE_DONE: begin
                busy = 1'b1;
                done = 1'b1;
            end


            default: begin
                busy = 1'b0;
            end

        endcase
    end


    // -------------------------------------------------------------------------
    // Регистры состояния, индекса и счётчика паузы
    // -------------------------------------------------------------------------

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            state        <= STATE_IDLE;
            bit_index    <= '0;
            settle_count <= '0;
        end else begin
            state <= next_state;


            /*
             * При новом запуске начинаем с response-бита 0.
             */
            if ((state == STATE_IDLE) && start) begin
                bit_index <= '0;
            end

            /*
             * После сохранения текущего результата переходим
             * к следующему response-биту.
             *
             * response_builder на этом же фронте видит старое
             * значение bit_index и сохраняет бит в нужную позицию.
             */
            else if (
                (state == STATE_STORE_RESULT) &&
                (bit_index != LAST_BIT_INDEX)
            ) begin
                bit_index <= bit_index + 1'b1;
            end


            /*
             * Счётчик работает только в состоянии STATE_SETTLE.
             */
            if (state == STATE_SETTLE) begin
                if (next_state == STATE_SETTLE)
                    settle_count <= settle_count + 1'b1;
                else
                    settle_count <= '0;
            end else begin
                settle_count <= '0;
            end
        end
    end

endmodule