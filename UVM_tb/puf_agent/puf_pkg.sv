package puf_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int unsigned CHALLENGE_WIDTH = 6;

    `include "puf_transaction.sv"

    `include "puf_sequencer.sv"
    
    `include "../sequences/puf_base_sequence.sv"
    `include "../sequences/puf_single_measure_sequence.sv"
    `include "../sequences/puf_random_challenge_sequence.sv"
    `include "../sequences/puf_repeated_measure_sequence.sv"
    `include "../sequences/puf_boundary_challenge_sequence.sv"

endpackage: puf_pkg
