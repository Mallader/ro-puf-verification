module top #(
    parameter integer NUM_RO           = 8,
    parameter integer RESPONSE_BITS    = 16,
    parameter integer COUNTER_WIDTH    = 32,
    parameter integer WINDOW_CYCLES    = 270_000,
    parameter integer RO_SETTLE_CYCLES = 16,
    parameter integer CHALLENGE_WIDTH  = 32,

    // Пауза между последовательными запусками.
    // При clk27 = 27 МГц значение 27_000_000 соответствует 1 секунде.
    parameter integer RESTART_CYCLES   = 27_000_000
) (
    input  logic       clk27,
    input  logic       rst_n,

    // Встроенные LED Tang Nano 9K активны низким уровнем.
    output logic [5:0] led
);

    localparam integer RESTART_WIDTH =
        (RESTART_CYCLES <= 1) ? 1 : $clog2(RESTART_CYCLES);

    localparam logic [RESTART_WIDTH-1:0] RESTART_LAST =
        RESTART_CYCLES - 1;


    // -------------------------------------------------------------------------
    // Интерфейс puf_core
    // -------------------------------------------------------------------------

    logic                        start;
    logic [CHALLENGE_WIDTH-1:0]  challenge;

    logic                        busy;
    logic                        ready;

    logic [RESPONSE_BITS-1:0]    response;

    logic [COUNTER_WIDTH-1:0]    debug_count_a;
    logic [COUNTER_WIDTH-1:0]    debug_count_b;


    // -------------------------------------------------------------------------
    // Основной PUF-блок
    // -------------------------------------------------------------------------

    puf_core #(
        .NUM_RO           (NUM_RO),
        .RESPONSE_BITS    (RESPONSE_BITS),
        .COUNTER_WIDTH    (COUNTER_WIDTH),
        .WINDOW_CYCLES    (WINDOW_CYCLES),
        .RO_SETTLE_CYCLES (RO_SETTLE_CYCLES),
        .CHALLENGE_WIDTH  (CHALLENGE_WIDTH)
    ) u_puf_core (
        .clk27         (clk27),
        .rst_n         (rst_n),

        .start         (start),
        .challenge     (challenge),

        .busy          (busy),
        .ready         (ready),

        .response      (response),

        .debug_count_a (debug_count_a),
        .debug_count_b (debug_count_b)
    );


    // -------------------------------------------------------------------------
    // Периодический автоматический запуск
    // -------------------------------------------------------------------------

    logic [RESTART_WIDTH-1:0] restart_counter;

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            restart_counter <= '0;
            start           <= 1'b0;
        end else begin
            /*
             * start всегда является импульсом длительностью
             * один такт clk27.
             */
            start <= 1'b0;

            /*
             * Пока puf_core занят, счётчик следующего запуска
             * удерживается в нуле.
             */
            if (busy) begin
                restart_counter <= '0;
            end else if (restart_counter == RESTART_LAST) begin
                restart_counter <= '0;
                start           <= 1'b1;
            end else begin
                restart_counter <= restart_counter + 1'b1;
            end
        end
    end


    // -------------------------------------------------------------------------
    // Обнаружение появления нового готового response
    // -------------------------------------------------------------------------

    logic busy_d;
    logic busy_fall;

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n)
            busy_d <= 1'b0;
        else
            busy_d <= busy;
    end

    assign busy_fall = busy_d && !busy;


    // -------------------------------------------------------------------------
    // Сохранение результата и изменение challenge
    // -------------------------------------------------------------------------

    logic [RESPONSE_BITS-1:0] response_latched;

    logic result_valid;
    logic completion_toggle;
    logic counters_nonzero;

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            challenge         <= '0;
            response_latched  <= '0;

            result_valid      <= 1'b0;
            completion_toggle <= 1'b0;
            counters_nonzero  <= 1'b0;
        end else if (busy_fall) begin
            response_latched <= response;

            counters_nonzero <=
                (debug_count_a != '0) &&
                (debug_count_b != '0);

            result_valid      <= 1'b1;
            completion_toggle <= ~completion_toggle;

            challenge <= challenge + RESPONSE_BITS;
        end
    end


    // -------------------------------------------------------------------------
    // Индикация на LED
    // -------------------------------------------------------------------------

    logic [5:0] led_on;

    always_comb begin
        led_on = 6'b000000;

        /*
         * LED0 горит во время формирования response.
         */
        led_on[0] = busy;

        /*
         * LED1 горит, когда готов полный response.
         * ready удерживается до следующего запуска.
         */
        led_on[1] = ready && result_valid;

        /*
         * LED2 меняет состояние после каждого полностью
         * завершённого формирования response.
         */
        led_on[2] = completion_toggle;

        /*
         * LED3 горит, если оба raw counter последней пары
         * имеют ненулевые значения.
         */
        led_on[3] = result_valid && counters_nonzero;

        /*
         * LED4 отображает младший бит последнего response.
         */
        led_on[4] = result_valid && response_latched[0];

        /*
         * LED5 отображает XOR всех битов response.
         * Это позволяет визуально видеть изменение response
         * при последовательном изменении challenge.
         */
        led_on[5] = result_valid && (^response_latched);

        /*
         * Встроенные светодиоды Tang Nano 9K
         * включаются низким уровнем.
         */
        led = ~led_on;
    end

endmodule