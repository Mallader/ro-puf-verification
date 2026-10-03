class puf_repeated_measure_sequence extends puf_base_sequence;

    `uvm_object_utils(puf_repeated_measure_sequence)

    int unsigned              num_items          = 10;
    bit [CHALLENGE_WIDTH-1:0] repeated_challenge = 'h1FF;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task body();
        puf_transaction req;

        for (int unsigned i = 0; i < num_items; i++) begin
            req = puf_transaction::type_id::create($sformatf("req_%0d", i));
            start_item(req);
            if (!req.randomize() with {challenge == repeated_challenge;}) begin
                `uvm_fatal("RANDFAIL", $sformatf("puf_transaction_%0d randomization failed", i))
            end
            finish_item(req);
        end
    endtask: body

endclass: puf_repeated_measure_sequence
