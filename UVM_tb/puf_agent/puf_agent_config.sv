class puf_agent_config extends uvm_object;

    uvm_active_passive_enum is_active       = UVM_ACTIVE;
    bit                     checks_enable   = 1'b1;
    bit                     coverage_enable = 1'b1;
    int unsigned            ready_timeout   = 1_000_000;

    virtual puf_core_if vif;

    `uvm_object_utils(puf_agent_config)

    function new(string name = "");
        super.new(name);
    endfunction: new

endclass: puf_agent_config
