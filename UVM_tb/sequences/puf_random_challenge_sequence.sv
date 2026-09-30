class puf_random_challenge_sequence extends puf_base_sequence;

    `uvm_object_utils(puf_random_challenge_sequence)

    int unsigned num_items = 10;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task body();
        for (int unsigned i = 0; i < num_items; i++) begin
            puf_transaction req;

            req = puf_transaction::type_id::create($sformatf("req_%0d", i));

            start_item(req);

            if (!req.randomize()) begin
                `uvm_fatal("RANDFAIL", $sformatf("puf_transaction_%0d randomization failed", i))
            end
            
            finish_item(req);
        end
    endtask: body

endclass: puf_random_challenge_sequence
