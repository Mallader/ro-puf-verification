class puf_transaction extends uvm_sequence_item;

    rand bit [CHALLENGE_WIDTH-1:0] challenge;
    rand int unsigned              start_delay;

    `uvm_object_utils(puf_transaction)

    function new(string name = "");
        super.new(name);
    endfunction: new

endclass: puf_transaction
