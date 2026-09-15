package puf_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int unsigned CHALLENGE_WIDTH = 32;

    `include "puf_transaction.sv"

endpackage: puf_pkg
