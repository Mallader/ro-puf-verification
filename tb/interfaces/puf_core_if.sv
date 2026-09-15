timeunit 1ns;
timeprecision 1ps;

interface puf_core_if #(
    parameter integer  NUM_RO                    = 8,
    parameter integer  RESPONSE_BITS             = 16,
    parameter integer  COUNTER_WIDTH             = 32,
    parameter integer  WINDOW_CYCLES             = 270_000,
    parameter integer  RO_SETTLE_CYCLES          = 16,
    parameter integer  CHALLENGE_WIDTH           = 32,
    parameter realtime HALF_PERIODS [0:NUM_RO-1] = '{default:5ns},
    parameter bit      ENABLED [0:NUM_RO-1]      = '{default:1'b1},
    parameter int      PROFILE                   = 0
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
    endclocking: drv_cb

    clocking mon_cb @(posedge clk27);
        default input #1step;

        input  rst_n, start, challenge, busy, ready, response, debug_count_a, debug_count_b;
    endclocking: mon_cb

    modport dut_mp (
        input  clk27,
        input  rst_n,
        input  start,
        input  challenge,

        output busy,
        output ready,
        output response,
        output debug_count_a,
        output debug_count_b
    );

    modport drv_mp (
        clocking drv_cb,
        input    clk27,
        output   rst_n
    );

    modport mon_mp (
        clocking mon_cb,
        input    clk27,
        input    rst_n
    );

    modport checker_mp (
        clocking mon_cb,
        input clk27,
        input rst_n,
        input start,
        input challenge,

        input busy,
        input ready,
        input response,
        input debug_count_a,
        input debug_count_b
    );

endinterface: puf_core_if
