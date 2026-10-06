class puf_driver extends uvm_driver #(puf_transaction);

    `uvm_component_utils(puf_driver)

    puf_transaction     req;
    puf_agent_config    cfg;
    virtual puf_core_if vif;

    function new (string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(puf_agent_config)::get(
                this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("NOCFG",
                {"config must be set for: ",
                 get_full_name(), ".cfg"});

        vif = cfg.vif;

        if (vif == null)
            `uvm_fatal("NOVIF",
                {"virtual interface must be set for: ",
                 get_full_name(), ".vif"});
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);

            drive_item(req);

            seq_item_port.item_done();
        end
    endtask: run_phase

    task drive_item (puf_transaction req);
        `uvm_info(get_type_name(),
                  $sformatf("PUF_DRIVER: challenge = %0h, start_delay = %0d",
                            req.challenge, req.start_delay),
                  UVM_MEDIUM)
    endtask: drive_item

endclass: puf_driver
