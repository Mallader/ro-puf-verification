module gate_timer #(
    parameter integer WINDOW_CYCLES = 270_000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,

    output logic gate_en
);

    // Минимальная ширина счётчика — один бит.
    localparam integer COUNTER_WIDTH =
        (WINDOW_CYCLES <= 1) ? 1 : $clog2(WINDOW_CYCLES);

    localparam logic [COUNTER_WIDTH-1:0] LAST_COUNT =
        WINDOW_CYCLES - 1;

    logic [COUNTER_WIDTH-1:0] cycle_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= '0;
            gate_en     <= 1'b0;
        end else begin
            if (!gate_en) begin
                // Состояние ожидания.
                cycle_count <= '0;

                if (start) begin
                    gate_en <= 1'b1;
                end
            end else begin
                // Измерительное окно активно.
                if (cycle_count == LAST_COUNT) begin
                    cycle_count <= '0;
                    gate_en     <= 1'b0;
                end else begin
                    cycle_count <= cycle_count + 1'b1;
                end
            end
        end
    end

endmodule