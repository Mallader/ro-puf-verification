module puf_peripheral #(
    parameter integer NUM_RO           = 8,
    parameter integer RESPONSE_BITS    = 16,
    parameter integer COUNTER_WIDTH    = 32,
    parameter integer WINDOW_CYCLES    = 270_000,
    parameter integer RO_SETTLE_CYCLES = 16
) (
    input  logic         clk27,
    input  logic         rst_n,

    // Интерфейс memory-mapped slave.
    // mem_valid должен быть предварительно декодирован
    // в soc_interconnect.sv именно для PUF-периферии.
    input  logic         mem_valid,
    input  logic [31:0]  mem_addr,
    input  logic [31:0]  mem_wdata,
    input  logic [3:0]   mem_wstrb,

    output logic         mem_ready,
    output logic [31:0]  mem_rdata
);

    // -------------------------------------------------------------------------
    // Карта локальных регистров
    // -------------------------------------------------------------------------

    localparam logic [5:0] REG_CONTROL   = 6'h00;
    localparam logic [5:0] REG_STATUS    = 6'h04;
    localparam logic [5:0] REG_CHALLENGE = 6'h08;
    localparam logic [5:0] REG_RESPONSE  = 6'h0C;
    localparam logic [5:0] REG_COUNT_A   = 6'h10;
    localparam logic [5:0] REG_COUNT_B   = 6'h14;

    /*
     * В текущей архитектуре:
     *
     * RESPONSE_BITS = 16
     * COUNTER_WIDTH = 32
     *
     * Если ширина будет больше 32 бит, через соответствующий
     * регистр будут доступны младшие 32 бита.
     */
    localparam integer RESPONSE_READ_BITS =
        (RESPONSE_BITS < 32) ? RESPONSE_BITS : 32;

    localparam integer COUNTER_READ_BITS =
        (COUNTER_WIDTH < 32) ? COUNTER_WIDTH : 32;


    // -------------------------------------------------------------------------
    // Программно-доступный регистр challenge
    // -------------------------------------------------------------------------

    logic [31:0] challenge_reg;


    // -------------------------------------------------------------------------
    // Интерфейс puf_core
    // -------------------------------------------------------------------------

    logic                         core_start;
    logic                         core_busy;
    logic                         core_ready;

    logic [RESPONSE_BITS-1:0]     core_response;
    logic [COUNTER_WIDTH-1:0]     core_count_a;
    logic [COUNTER_WIDTH-1:0]     core_count_b;


    // -------------------------------------------------------------------------
    // Декодирование шинной транзакции
    // -------------------------------------------------------------------------

    logic bus_write;

    /*
     * В интерфейсе PicoRV32 операция записи определяется
     * ненулевым значением mem_wstrb.
     *
     * При чтении:
     *
     *     mem_wstrb = 4'b0000
     */
    assign bus_write =
        mem_valid && (|mem_wstrb);


    /*
     * CONTROL.START является командой write-one.
     *
     * Сигнал формируется комбинационно из текущей шинной транзакции,
     * поэтому puf_core видит start на том же фронте clk27, на котором
     * завершается запись CPU.
     *
     * Команда во время core_busy подтверждается шиной, но не запускает
     * новое измерение.
     */
    always_comb begin
        core_start = 1'b0;

        if (
            bus_write &&
            (mem_addr[5:0] == REG_CONTROL) &&
            mem_wstrb[0] &&
            mem_wdata[0] &&
            !core_busy
        ) begin
            core_start = 1'b1;
        end
    end


    // -------------------------------------------------------------------------
    // Записываемые регистры
    // -------------------------------------------------------------------------

    always_ff @(posedge clk27 or negedge rst_n) begin
        if (!rst_n) begin
            challenge_reg <= 32'h0000_0000;
        end else if (
            bus_write &&
            (mem_addr[5:0] == REG_CHALLENGE)
        ) begin

            /*
             * Поддержка побайтовой записи через mem_wstrb.
             */

            if (mem_wstrb[0])
                challenge_reg[7:0] <= mem_wdata[7:0];

            if (mem_wstrb[1])
                challenge_reg[15:8] <= mem_wdata[15:8];

            if (mem_wstrb[2])
                challenge_reg[23:16] <= mem_wdata[23:16];

            if (mem_wstrb[3])
                challenge_reg[31:24] <= mem_wdata[31:24];
        end
    end


    // -------------------------------------------------------------------------
    // Тракт чтения и завершение шинной транзакции
    // -------------------------------------------------------------------------

    always_comb begin

        /*
         * Периферия не добавляет тактов ожидания.
         *
         * soc_interconnect.sv должен подавать mem_valid только для
         * обращений в адресную область PUF.
         */
        mem_ready = mem_valid;
        mem_rdata = 32'h0000_0000;

        case (mem_addr[5:0])

            REG_CONTROL: begin
                /*
                 * START является командным битом и при чтении
                 * возвращает ноль.
                 */
                mem_rdata = 32'h0000_0000;
            end


            REG_STATUS: begin
                mem_rdata[0] = core_busy;
                mem_rdata[1] = core_ready;
            end


            REG_CHALLENGE: begin
                mem_rdata = challenge_reg;
            end


            REG_RESPONSE: begin
                mem_rdata[RESPONSE_READ_BITS-1:0] =
                    core_response[RESPONSE_READ_BITS-1:0];
            end


            REG_COUNT_A: begin
                mem_rdata[COUNTER_READ_BITS-1:0] =
                    core_count_a[COUNTER_READ_BITS-1:0];
            end


            REG_COUNT_B: begin
                mem_rdata[COUNTER_READ_BITS-1:0] =
                    core_count_b[COUNTER_READ_BITS-1:0];
            end


            default: begin
                mem_rdata = 32'h0000_0000;
            end

        endcase
    end


    // -------------------------------------------------------------------------
    // Ядро PUF
    // -------------------------------------------------------------------------

    puf_core #(
        .NUM_RO           (NUM_RO),
        .RESPONSE_BITS    (RESPONSE_BITS),
        .COUNTER_WIDTH    (COUNTER_WIDTH),
        .WINDOW_CYCLES    (WINDOW_CYCLES),
        .RO_SETTLE_CYCLES (RO_SETTLE_CYCLES),
        .CHALLENGE_WIDTH  (32)
    ) u_puf_core (
        .clk27         (clk27),
        .rst_n         (rst_n),

        .start         (core_start),
        .challenge     (challenge_reg),

        .busy          (core_busy),
        .ready         (core_ready),

        .response      (core_response),
        .debug_count_a (core_count_a),
        .debug_count_b (core_count_b)
    );

endmodule