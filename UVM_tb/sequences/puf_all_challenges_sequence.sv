class puf_all_challenges_sequence extends puf_base_sequence;

    `uvm_object_utils(puf_all_challenges_sequence)

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task body();
        bit [CHALLENGE_WIDTH-1:0] challenge_value = '0;
        puf_transaction req;

        forever begin
            req = puf_transaction::type_id::create($sformatf("req_%0h", challenge_value));
            start_item(req);
            if (!req.randomize() with {challenge == challenge_value;}) begin
                `uvm_fatal("RANDFAIL", $sformatf("puf_transaction_%0h randomization failed", challenge_value))
            end
            finish_item(req);

            if (challenge_value == '1)
                break;

            challenge_value++;
        end
    endtask: body

endclass: puf_all_challenges_sequence
