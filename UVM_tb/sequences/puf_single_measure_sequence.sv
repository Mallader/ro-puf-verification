class puf_single_measure_sequence extends puf_base_sequence;

    `uvm_object_utils(puf_single_measure_sequence)

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task body();

        puf_transaction req;

        req = puf_transaction::type_id::create("req");

        start_item(req);

        if (!req.randomize()) begin
            `uvm_fatal("RANDFAIL", "puf_transaction randomization failed")
        end
        
        finish_item(req);

    endtask: body

endclass: puf_single_measure_sequence
