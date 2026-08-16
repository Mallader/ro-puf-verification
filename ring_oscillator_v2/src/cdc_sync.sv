module cdc_sync (
    input  logic clk,
    input  logic rst_n,
    input  logic async_in,

    output logic sync_out
);

    // Атрибуты помогают синтезатору распознать цепочку
    // как CDC-синхронизатор и не удалять триггеры.
    (* ASYNC_REG = "TRUE", KEEP = "TRUE" *)
    logic sync_ff1;

    (* ASYNC_REG = "TRUE", KEEP = "TRUE" *)
    logic sync_ff2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= async_in;
            sync_ff2 <= sync_ff1;
        end
    end

    assign sync_out = sync_ff2;

endmodule