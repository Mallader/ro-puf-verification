timeunit 1ns;
timeprecision 1ps;

module puf_core_model (
    puf_core_if.dut_mp vif
);

logic [vif.CHALLENGE_WIDTH - 1:0] challenge_q;

    always_ff @(posedge vif.clk27 or negedge vif.rst_n) begin
        if (!vif.rst_n) begin
            vif.busy          <= 1'b0;
            vif.ready         <= 1'b0;
            vif.response      <= '0;
            vif.debug_count_a <= '0;
            vif.debug_count_b <= '0;
        end
        else if (vif.start && !vif.busy) begin
            vif.busy     <= 1'b1;
            vif.ready    <= 1'b0;
            challenge_q <= vif.challenge;
        end
        else if (vif.busy) begin
            vif.busy          <= 1'b0;
            vif.ready         <= 1'b1;
            vif.response      <= challenge_q;
            vif.debug_count_a <= challenge_q;
            vif.debug_count_b <= challenge_q;
        end
    end

endmodule
