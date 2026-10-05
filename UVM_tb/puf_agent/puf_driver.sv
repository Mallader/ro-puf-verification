class puf_driver extends uvm_driver #(puf_transaction);

    `uvm_component_utils(puf_driver)

    puf_transaction req;

    function new (string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

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
