module top;

    import puf_pkg::*;

    puf_transaction   tr;
    puf_base_sequence seq;
    puf_sequencer     sequencer;

    initial begin
        tr        = puf_transaction::type_id::create("tr");
        seq       = puf_base_sequence::type_id::create("seq");
        sequencer = puf_sequencer::type_id::create("sequencer", null);

        repeat (20) begin
            if (!tr.randomize())
                $fatal(1, "puf_transaction randomization failed");

            $display(
                "challenge = 0x%0h, start_delay = %0d",
                tr.challenge,
                tr.start_delay
            );
        end

        if (!tr.randomize() with {
            start_delay == 0;
        })
            $fatal(1, "valid inline constraint failed");

        if (tr.randomize() with {
            start_delay > MAX_START_DELAY;
        })
            $fatal(1, "conflicting constraint unexpectedly succeeded");

        $display("PUF TRANSACTION SMOKE TEST PASSED");
        $finish;
    end

endmodule: top
