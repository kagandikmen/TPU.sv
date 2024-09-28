// Instruction FIFO
// Created: 2024-09-27
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module instr_fifo
    #(
        parameter int FIFO_DEPTH = 32
    )(
        input logic clk,
        input logic rst,
        input word_type lower_word,
        input word_type middle_word,
        input halfword_type upper_word,
        input logic [2:0] write_en,

        output instr_type data_out,
        input logic next_en,

        output logic empty,
        output logic full
    );

    logic [2:0] empty_vector, full_vector;
    word_type lower_output, middle_output;
    halfword_type upper_output;

    fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(4*BYTE_WIDTH)
    ) fifo_0 (
        .clk(clk),
        .rst(rst),
        .data_in(lower_word),
        .write_en(write_en[0]),
        .data_out(lower_output),
        .next_en(next_en),
        .empty(empty_vector[0]),
        .full(full_vector[0])
    );

    fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(4*BYTE_WIDTH)
    ) fifo_1 (
        .clk(clk),
        .rst(rst),
        .data_in(middle_word),
        .write_en(write_en[1]),
        .data_out(middle_output),
        .next_en(next_en),
        .empty(empty_vector[1]),
        .full(full_vector[1])
    );

    fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(2*BYTE_WIDTH)
    ) fifo_2 (
        .clk(clk),
        .rst(rst),
        .data_in(upper_word),
        .write_en(write_en[2]),
        .data_out(upper_output),
        .next_en(next_en),
        .empty(empty_vector[2]),
        .full(full_vector[2])
    );

    always_comb
    begin
        empty = empty_vector[0] | empty_vector[1] | empty_vector[2];
        full = full_vector[0] | full_vector[1] | full_vector[2];

        data_out = {upper_output, middle_output, lower_output};
    end

endmodule
