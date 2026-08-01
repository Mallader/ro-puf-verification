interface puf_core_if #(
    parameter int unsigned CHALLENGE_WIDTH = 32,
    parameter int unsigned RESPONSE_BITS   = 16,
    parameter int unsigned COUNTER_WIDTH   = 32
) (
    input logic clk27
);

    // Управление DUT
    logic rst_n, start; 
    logic [CHALLENGE_WIDTH - 1:0] challenge;

    // Состояние DUT
    logic busy, ready;

    // Результаты операции
    logic [RESPONSE_BITS - 1:0] response; 
    logic [COUNTER_WIDTH - 1:0] debug_count_a, debug_count_b;

    clocking drv_cb @(posedge clk27);
        default input #1step output #0;

        output start, challenge;
        input  busy, ready;
    endclocking

    clocking mon_cb @(posedge clk27);
        default input #1step;

        input  rst_n, start, challenge, busy, ready, response, debug_count_a, debug_count_b;
    endclocking

endinterface
