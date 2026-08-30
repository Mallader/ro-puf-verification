timeunit 1ns;
timeprecision 1ps;

interface ro_pair_measure_if #(
    parameter int      NUM_RO                    = 4,
    parameter int      PROFILE_NORMAL            = 0,
    parameter int      PROFILE_TIE_LAST          = 1,
    parameter int      PROFILE_CLOSE             = 2,
    parameter int      COUNTER_WIDTH             = 16,
    parameter int      WINDOW_CYCLES             = 100,
    parameter realtime HALF_PERIODS [0:NUM_RO-1] = '{default:5ns},
    parameter int      RO_A_INDEX                = NUM_RO - 1,
    parameter int      RO_B_INDEX                = NUM_RO - 2
) (
    input logic clk27
);
    logic                     rst_n;
    logic                     start;
    logic                     busy;
    logic                     done;
    logic                     puf_bit;
    logic                     tie;
    logic [COUNTER_WIDTH-1:0] count_a;
    logic [COUNTER_WIDTH-1:0] count_b;

    clocking drv_cb @(posedge clk27);
        default input #1step output #0;

        output start, rst_n;
        input  busy, done;
    endclocking

    clocking mon_cb @(posedge clk27);
        default input #1step;

        input  rst_n, start, busy, done, puf_bit, tie, count_a, count_b;
    endclocking

    modport dut_mp (
        input  clk27,
        input  rst_n,
        input  start,

        output busy,
        output done,
        output puf_bit,
        output tie,
        output count_a,
        output count_b
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
        input  clk27,
        input  rst_n,
        input  start,
        input busy,
        input done,
        input puf_bit,
        input tie,
        input count_a,
        input count_b
    );

endinterface
