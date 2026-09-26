class puf_base_sequence extends uvm_sequence #(puf_transaction);

    `uvm_object_utils(puf_base_sequence)
    
    function new(string name = "");
        super.new(name);
    endfunction

endclass: puf_base_sequence
