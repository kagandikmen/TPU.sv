// Common package for RTL description of TPU
// Created: 2024-09-28
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

package tpu_pkg;
    parameter int BYTE_WIDTH = 8;

    typedef logic [16:0] halfword_type;
    typedef logic [31:0] word_type;

    typedef struct packed   // instr_type
    {
        logic [23:0] buff_addr;
        logic [15:0] acc_addr;
        logic [31:0] length;
        logic [7:0] opcode; 
    } instr_type;

    function instr_type bit_to_instr(input logic [79:0] bits);
        instr_type result;
        result.buff_addr = bits[79:56];
        result.acc_addr = bits[55:40];
        result.length = bits[39:8];
        result.opcode = bits[7:0];
        return result;
    endfunction

endpackage
