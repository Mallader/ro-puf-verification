module ro_pair_measure #(
    parameter integer COUNTER_WIDTH = 32,
    parameter integer WINDOW_CYCLES = 270_000
)(
    input  logic                     clk27,
    input  logic                     rst_n,
    input  logic                     start,

    // Выбранные генераторы из ro_array.
    input  logic                     ro_clk_a,
    input  logic                     ro_clk_b,

    output logic                     busy,
    output logic                     done,

    output logic                     puf_bit,
    output logic                     tie,

    output logic [COUNTER_WIDTH-1:0] count_a,
    output logic [COUNTER_WIDTH-1:0] count_b
);

    /*
     * Сигнал start принимается только тогда, когда модуль
     * не выполняет предыдущее измерение.
     */
    logic start_accepted;

    assign start_accepted = start && !busy;

    /*
     * Общее измерительное окно формируется в домене clk27.
     */
    logic measure_gate_clk27;

    gate_timer #(
        .WINDOW_CYCLES (WINDOW_CYCLES)
    ) u_gate_timer (
        .clk     (clk27),
        .rst_n   (rst_n),
        .start   (start_accepted),
        .gate_en (measure_gate_clk27)
    );

    /*
     * Передача измерительного окна в домен каждого RO.
     */
    logic measure_gate_ro_a;
    logic measure_gate_ro_b;

    cdc_sync u_gate_sync_a (
        .clk      (ro_clk_a),
        .rst_n    (rst_n),
        .async_in (measure_gate_clk27),
        .sync_out (measure_gate_ro_a)
    );

    cdc_sync u_gate_sync_b (
        .clk      (ro_clk_b),
        .rst_n    (rst_n),
        .async_in (measure_gate_clk27),
        .sync_out (measure_gate_ro_b)
    );

    /*
     * Обнаружение начала и конца измерительного окна
     * отдельно в каждом RO-домене.
     */
    logic measure_gate_ro_a_d;
    logic measure_gate_ro_b_d;

    logic gate_rise_ro_a;
    logic gate_rise_ro_b;

    logic gate_fall_ro_a;
    logic gate_fall_ro_b;

    always_ff @(posedge ro_clk_a or negedge rst_n) begin
        if (!rst_n)
            measure_gate_ro_a_d <= 1'b0;
        else
            measure_gate_ro_a_d <= measure_gate_ro_a;
    end

    always_ff @(posedge ro_clk_b or negedge rst_n) begin
        if (!rst_n)
            measure_gate_ro_b_d <= 1'b0;
        else
            measure_gate_ro_b_d <= measure_gate_ro_b;
    end

    assign gate_rise_ro_a =
        measure_gate_ro_a && !measure_gate_ro_a_d;

    assign gate_rise_ro_b =
        measure_gate_ro_b && !measure_gate_ro_b_d;

    assign gate_fall_ro_a =
        !measure_gate_ro_a && measure_gate_ro_a_d;

    assign gate_fall_ro_b =
        !measure_gate_ro_b && measure_gate_ro_b_d;

    /*
     * Счётчики импульсов выбранных RO.
     *
     * В начале окна счётчик очищается.
     * Во время активного окна счётчик увеличивается.
     */
    logic [COUNTER_WIDTH-1:0] ro_count_a;
    logic [COUNTER_WIDTH-1:0] ro_count_b;

    ro_counter #(
        .WIDTH (COUNTER_WIDTH)
    ) u_ro_counter_a (
        .ro_clk (ro_clk_a),
        .rst_n  (rst_n),
        .clear  (gate_rise_ro_a),
        .enable (measure_gate_ro_a),
        .count  (ro_count_a)
    );

    ro_counter #(
        .WIDTH (COUNTER_WIDTH)
    ) u_ro_counter_b (
        .ro_clk (ro_clk_b),
        .rst_n  (rst_n),
        .clear  (gate_rise_ro_b),
        .enable (measure_gate_ro_b),
        .count  (ro_count_b)
    );

    /*
     * После окончания измерительного окна значения
     * счётчиков фиксируются в соответствующих RO-доменах.
     */
    logic [COUNTER_WIDTH-1:0] ro_count_snapshot_a;
    logic [COUNTER_WIDTH-1:0] ro_count_snapshot_b;

    snapshot #(
        .WIDTH (COUNTER_WIDTH)
    ) u_snapshot_a (
        .clk      (ro_clk_a),
        .rst_n    (rst_n),
        .capture  (gate_fall_ro_a),
        .data_in  (ro_count_a),
        .data_out (ro_count_snapshot_a)
    );

    snapshot #(
        .WIDTH (COUNTER_WIDTH)
    ) u_snapshot_b (
        .clk      (ro_clk_b),
        .rst_n    (rst_n),
        .capture  (gate_fall_ro_b),
        .data_in  (ro_count_b),
        .data_out (ro_count_snapshot_b)
    );

    /*
     * Toggle-сигналы сообщают домену clk27,
     * что соответствующий snapshot обновлён.
     */
    logic snapshot_toggle_ro_a;
    logic snapshot_toggle_ro_b;

    always_ff @(posedge ro_clk_a or negedge rst_n) begin
        if (!rst_n)
            snapshot_toggle_ro_a <= 1'b0;
        else if (gate_fall_ro_a)
            snapshot_toggle_ro_a <= ~snapshot_toggle_ro_a;
    end

    always_ff @(posedge ro_clk_b or negedge rst_n) begin
        if (!rst_n)
            snapshot_toggle_ro_b <= 1'b0;
        else if (gate_fall_ro_b)
            snapshot_toggle_ro_b <= ~snapshot_toggle_ro_b;
    end

    /*
     * Синхронизация событий готовности обратно в clk27.
     */
    logic snapshot_toggle_a_sync;
    logic snapshot_toggle_b_sync;

    cdc_sync u_snapshot_toggle_sync_a (
        .clk      (clk27),
        .rst_n    (rst_n),
        .async_in (snapshot_toggle_ro_a),
        .sync_out (snapshot_toggle_a_sync)
    );

    cdc_sync u_snapshot_toggle_sync_b (
        .clk      (clk27),
        .rst_n    (rst_n),
        .async_in (snapshot_toggle_ro_b),
        .sync_out (snapshot_toggle_b_sync)
    );

    /*
     * Значения toggle, существовавшие перед запуском
     * текущего измерения.
     */
    logic snapshot_toggle_a_start;
    logic snapshot_toggle_b_start;

    /*
     * Управление измерением и формирование результата.
     *
     * Многобитные snapshot-сигналы не синхронизируются
     * побитно. Они захватываются только после остановки
     * счётчиков и остаются неизменными к моменту прихода
     * синхронизированных toggle-событий.
     */
    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            busy                    <= 1'b0;
            done                    <= 1'b0;

            puf_bit                 <= 1'b0;
            tie                     <= 1'b0;

            count_a                 <= '0;
            count_b                 <= '0;

            snapshot_toggle_a_start <= 1'b0;
            snapshot_toggle_b_start <= 1'b0;
        end
        else begin
            /*
             * done является импульсом длительностью один clk27.
             */
            done <= 1'b0;

            if (start_accepted) begin
                busy <= 1'b1;

                snapshot_toggle_a_start <= snapshot_toggle_a_sync;
                snapshot_toggle_b_start <= snapshot_toggle_b_sync;
            end
            else if (
                busy &&
                (snapshot_toggle_a_sync != snapshot_toggle_a_start) &&
                (snapshot_toggle_b_sync != snapshot_toggle_b_start)
            ) begin
                count_a <= ro_count_snapshot_a;
                count_b <= ro_count_snapshot_b;

                if (ro_count_snapshot_a > ro_count_snapshot_b) begin
                    puf_bit <= 1'b1;
                    tie     <= 1'b0;
                end
                else if (ro_count_snapshot_a < ro_count_snapshot_b) begin
                    puf_bit <= 1'b0;
                    tie     <= 1'b0;
                end
                else begin
                    puf_bit <= 1'b0;
                    tie     <= 1'b1;
                end

                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end

endmodule