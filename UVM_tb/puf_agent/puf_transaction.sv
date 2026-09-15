class puf_transaction extends uvm_sequence_item;

    localparam int unsigned MAX_START_DELAY = 10;

    rand bit [CHALLENGE_WIDTH-1:0] challenge;
    rand int unsigned              start_delay;

    constraint c_start_delay {
        start_delay inside {[0:MAX_START_DELAY]};
    }

    `uvm_object_utils(puf_transaction)

    function new(string name = "");
        super.new(name);
    endfunction: new

endclass: puf_transaction
