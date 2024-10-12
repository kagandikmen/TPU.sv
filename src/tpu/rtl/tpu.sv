// TPU top module
// Created: 2024-10-11
// Modified: 2024-10-12

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "runtime_ctr.sv"
`include "instr_fifo.sv"
`include "tpu_core.sv"

import tpu_pkg::*;

module tpu
    #(
        parameter int MATRIX_WIDTH = 14,
        parameter int WEIGHT_BUFFER_DEPTH = 32768,
        parameter int UNIFIED_BUFFER_DEPTH = 4096
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        output  word_type runtime_count,

        input   word_type lower_instr_word,
        input   word_type middle_instr_word,
        input   halfword_type upper_instr_word,
        input   logic [2:0] instr_write_enable,

        output  logic instr_fifo_empty,
        output  logic instr_fifo_full,

        input   byte_type [MATRIX_WIDTH-1:0] weight_write_port,
        input   weight_addr_type weight_addr,
        input   logic weight_enable,
        input   logic [MATRIX_WIDTH-1:0] weight_write_enable,

        input   byte_type [MATRIX_WIDTH-1:0] buffer_write_port,
        output  byte_type [MATRIX_WIDTH-1:0] buffer_read_port,
        input   buffer_addr_type buffer_addr,
        input   logic buffer_enable,
        input   logic [MATRIX_WIDTH-1:0] buffer_write_enable,

        output  logic synchronize
    );
    
    // instr_fifo signals
    instr_type instr;
    logic empty, full;

    // tpu_core signals
    logic instr_enable, busy, synchronize_in;

    runtime_ctr #(
    ) runtime_ctr_tpu (
        .clk(clk),
        .rst(rst),
        .instr_en(instr_enable),
        .synch(synchronize_in),
        .ctr_val(runtime_count)
    );

    instr_fifo #(
        .FIFO_DEPTH(32)
    ) instr_fifo_tpu (
        .clk(clk),
        .rst(rst),
        .lower_word(lower_instr_word),
        .middle_word(middle_instr_word),
        .upper_word(upper_instr_word),
        .write_en(instr_write_enable),
        .data_out(instr),
        .next_en(instr_enable),
        .empty(empty),
        .full(full)
    );

    tpu_core #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
        .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH)
    ) tpu_core_tpu (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .weight_write_port(weight_write_port),
        .weight_addr(weight_addr),
        .weight_enable(weight_enable),
        .weight_write_enable(weight_write_enable),
        .buffer_write_port(buffer_write_port),
        .buffer_read_port(buffer_read_port),
        .buffer_addr(buffer_addr),
        .buffer_enable(buffer_enable),
        .buffer_write_enable(buffer_write_enable),
        .instr_port(instr),
        .instr_enable(instr_enable),
        .busy(busy),
        .synchronize(synchronize_in)
    );

    assign instr_fifo_empty = empty;
    assign instr_fifo_full = full;

    assign synchronize = synchronize_in;


    // instruction feed
    always_comb
    begin
        if(!busy && !empty)
            instr_enable = 1;
        else
            instr_enable = 0;
    end

endmodule
