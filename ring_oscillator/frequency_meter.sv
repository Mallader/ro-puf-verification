module frequency_meter #(
    parameter integer COUNTER_WIDTH = 32,
    parameter integer WINDOW_CYCLES = 270_000
) (
    input  logic                     clk27,
    input  logic                     rst_n,
    input  logic                     start,

    output logic                     busy,
    output logic                     done,
    output logic [COUNTER_WIDTH-1:0] pulse_count
);

    // ============================================================
    // Сигналы кольцевого генератора
    // ============================================================

    wire ro_clk;

    // ============================================================
    // Управление измерительным окном
    // ============================================================

    logic timer_start;

    logic measure_gate_clk27;
    logic measure_gate_ro;
    logic measure_gate_ro_d;

    logic gate_rise_ro;
    logic gate_fall_ro;

    // ============================================================
    // Счётчик и snapshot в домене ro_clk
    // ============================================================

    logic [COUNTER_WIDTH-1:0] ro_count;
    logic [COUNTER_WIDTH-1:0] ro_count_snapshot;

    // Toggle-сигнал сообщает clk27 о готовом snapshot.
    logic snapshot_toggle_ro;
    logic snapshot_toggle_clk27;
    logic snapshot_toggle_clk27_d;

    // Для детектирования фронта start.
    logic start_d;

    wire start_pulse;

    assign start_pulse = start & ~start_d;

    // ============================================================
    // Ring oscillator
    // ============================================================

    ring_oscillator u_ring_oscillator (
        .ro_clk (ro_clk)
    );

    // ============================================================
    // Таймер измерительного окна
    // ============================================================

    gate_timer #(
        .WINDOW_CYCLES (WINDOW_CYCLES)
    ) u_gate_timer (
        .clk      (clk27),
        .rst_n    (rst_n),
        .start    (timer_start),
        .gate_en  (measure_gate_clk27)
    );

    // ============================================================
    // CDC: clk27 -> ro_clk
    //
    // measure_gate_clk27 является одиночным управляющим сигналом,
    // поэтому для него используется двухтактный синхронизатор.
    // ============================================================

    cdc_sync u_gate_sync (
        .clk       (ro_clk),
        .rst_n     (rst_n),
        .async_in  (measure_gate_clk27),
        .sync_out  (measure_gate_ro)
    );

    // ============================================================
    // Детектирование начала и конца окна в домене ro_clk
    // ============================================================

    always_ff @(posedge ro_clk or negedge rst_n) begin
        if (!rst_n) begin
            measure_gate_ro_d <= 1'b0;
        end else begin
            measure_gate_ro_d <= measure_gate_ro;
        end
    end

    assign gate_rise_ro =  measure_gate_ro & ~measure_gate_ro_d;
    assign gate_fall_ro = ~measure_gate_ro &  measure_gate_ro_d;

    // ============================================================
    // Счётчик импульсов RO
    //
    // На gate_rise_ro счётчик очищается.
    // Пока measure_gate_ro = 1, счётчик считает фронты ro_clk.
    // После закрытия окна значение удерживается.
    // ============================================================

    ro_counter #(
        .WIDTH (COUNTER_WIDTH)
    ) u_ro_counter (
        .ro_clk  (ro_clk),
        .rst_n   (rst_n),
        .clear   (gate_rise_ro),
        .enable  (measure_gate_ro),
        .count   (ro_count)
    );

    // ============================================================
    // Захват остановленного счётчика
    //
    // Snapshot выполняется в том же домене ro_clk, поэтому
    // многобитное значение не читается во время изменения.
    // ============================================================

    snapshot #(
        .WIDTH (COUNTER_WIDTH)
    ) u_snapshot (
        .clk       (ro_clk),
        .rst_n     (rst_n),
        .capture   (gate_fall_ro),
        .data_in   (ro_count),
        .data_out  (ro_count_snapshot)
    );

    // ============================================================
    // Формирование события "snapshot готов"
    //
    // Короткий импульс из одного домена может быть пропущен другим
    // доменом, поэтому используется toggle-сигнал.
    // ============================================================

    always_ff @(posedge ro_clk or negedge rst_n) begin
        if (!rst_n) begin
            snapshot_toggle_ro <= 1'b0;
        end else if (gate_fall_ro) begin
            snapshot_toggle_ro <= ~snapshot_toggle_ro;
        end
    end

    // ============================================================
    // CDC: ro_clk -> clk27
    // ============================================================

    cdc_sync u_snapshot_toggle_sync (
        .clk       (clk27),
        .rst_n     (rst_n),
        .async_in  (snapshot_toggle_ro),
        .sync_out  (snapshot_toggle_clk27)
    );

    // ============================================================
    // Управление измерением в домене clk27
    //
    // ro_count_snapshot удерживается неизменным до следующего
    // измерения. К моменту обнаружения toggle-сигнала шина данных
    // уже стабильна несколько тактов clk27.
    // ============================================================

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            start_d                   <= 1'b0;
            timer_start               <= 1'b0;

            busy                      <= 1'b0;
            done                      <= 1'b0;
            pulse_count               <= '0;

            snapshot_toggle_clk27_d   <= 1'b0;
        end else begin
            start_d                  <= start;
            snapshot_toggle_clk27_d  <= snapshot_toggle_clk27;

            // Однотактные сигналы по умолчанию сброшены.
            timer_start <= 1'b0;
            done        <= 1'b0;

            // Новый запуск принимается только в состоянии idle.
            if (start_pulse && !busy) begin
                timer_start <= 1'b1;
                busy        <= 1'b1;
            end

            // Изменение toggle означает, что новый snapshot готов.
            if (snapshot_toggle_clk27 != snapshot_toggle_clk27_d) begin
                pulse_count <= ro_count_snapshot;
                busy        <= 1'b0;
                done        <= 1'b1;
            end
        end
    end

endmodule