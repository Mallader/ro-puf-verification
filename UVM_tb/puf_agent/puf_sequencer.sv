class puf_sequencer extends uvm_sequencer #(puf_transaction);

    `uvm_component_utils(puf_sequencer)

    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass: puf_sequencer
