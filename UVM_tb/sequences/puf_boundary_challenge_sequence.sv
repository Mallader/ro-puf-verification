class puf_boundary_challenge_sequence extends puf_base_sequence;

    `uvm_object_utils(puf_boundary_challenge_sequence)

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task body();

        puf_transaction req_min;
        puf_transaction req_max;

        req_min = puf_transaction::type_id::create("req_min");
        start_item(req_min);
        if (!req_min.randomize() with {challenge == '0;}) begin
            `uvm_fatal("RANDFAIL", "puf_transaction randomization failed")
        end
        finish_item(req_min);

        req_max = puf_transaction::type_id::create("req_max");
        start_item(req_max);
        if (!req_max.randomize() with {challenge == '1;}) begin
            `uvm_fatal("RANDFAIL", "puf_transaction randomization failed")
        end
        finish_item(req_max);

    endtask: body

endclass: puf_boundary_challenge_sequence
