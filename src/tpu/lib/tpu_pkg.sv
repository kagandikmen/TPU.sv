// Common package for RTL description of TPU
// Created: 2024-09-28
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

package tpu_pkg;

    parameter int BYTE_WIDTH = 8;
    parameter int EXTENDED_BYTE_WIDTH = BYTE_WIDTH + 1;

    parameter int BUFFER_ADDR_WIDTH = 24;
    parameter int ACCUMULATOR_ADDR_WIDTH = 16;
    parameter int WEIGHT_ADDR_WIDTH = BUFFER_ADDR_WIDTH + ACCUMULATOR_ADDR_WIDTH;
    parameter int OPCODE_WIDTH = 8;
    parameter int LENGTH_WIDTH = 32;

    typedef enum bit {false=0, true=1} boolean;     // default value is false

    typedef logic [BYTE_WIDTH-1:0] byte_type;
    typedef logic [EXTENDED_BYTE_WIDTH-1:0] extended_byte_type;
    typedef logic [2*EXTENDED_BYTE_WIDTH-1:0] mul_halfword_type;
    typedef logic [16:0] halfword_type;
    typedef logic [31:0] word_type;

    typedef logic [BUFFER_ADDR_WIDTH-1:0] buffer_addr_type;
    typedef logic [ACCUMULATOR_ADDR_WIDTH-1:0] accumulator_addr_type;
    typedef logic [WEIGHT_ADDR_WIDTH-1:0] weight_addr_type;

    typedef enum logic[3:0] {no_activation, relu, relu6, crelu, elu, selu, softplus, softsign, dropout, sigmoid, tanh} activation_type;

    typedef struct packed   // instr_type
    {
        buffer_addr_type buffer_addr;
        logic [15:0] acc_addr;
        logic [31:0] length;
        logic [7:0] opcode; 
    } instr_type;

    instr_type INIT_INSTR = '{default: 0};

    function instr_type bit_to_instr(input logic [79:0] bits);
        instr_type result;
        result.buffer_addr = bits[79:56];
        result.acc_addr = bits[55:40];
        result.length = bits[39:8];
        result.opcode = bits[7:0];
        return result;
    endfunction

endpackage
