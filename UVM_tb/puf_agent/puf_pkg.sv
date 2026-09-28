package puf_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int unsigned CHALLENGE_WIDTH = 32;

    `include "puf_transaction.sv"

    `include "puf_sequencer.sv"
    
    `include "../sequences/puf_base_sequence.sv"
    `include "../sequences/puf_single_measure_sequence.sv"

endpackage: puf_pkg
