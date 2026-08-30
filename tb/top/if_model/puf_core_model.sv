timeunit 1ns;
timeprecision 1ps;

module puf_core_model (
    puf_core_if.dut_mp vif
);

localparam CYCLES_BEFORE_READY = 4;

logic [vif.CHALLENGE_WIDTH - 1:0] challenge_q;
logic [CYCLES_BEFORE_READY - 1:0] queue = '0;

always_ff @(posedge vif.clk27 or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
        vif.busy          <= 1'b0;
        vif.ready         <= 1'b0;
        vif.response      <= '0;
        vif.debug_count_a <= '0;
        vif.debug_count_b <= '0;
        queue             <= '0;

    end
    else if (vif.start && !vif.busy) begin
        vif.busy    <= 1'b1;
        vif.ready   <= 1'b0;
        challenge_q <= vif.challenge;
        queue       <= {{(CYCLES_BEFORE_READY - 1){1'b0}}, 1'b1}; 
    end
    else if (vif.busy) begin
        vif.busy          <= !queue[CYCLES_BEFORE_READY - 1];
        vif.ready         <= queue[CYCLES_BEFORE_READY - 1];
        vif.response      <= challenge_q;
        vif.debug_count_a <= challenge_q;
        vif.debug_count_b <= challenge_q;
        queue             <= queue << 1;
    end
end

endmodule
