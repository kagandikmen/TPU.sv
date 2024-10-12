// Testbench for TPU top module
// Created: 2024-10-12
// Modified: 2024-10-12

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/tpu.sv"

import tpu_pkg::*;

module tb_tpu
    #(
    )(
    );

    localparam MATRIX_WIDTH = 14;
    localparam WEIGHT_BUFFER_DEPTH = 32768; 
    localparam UNIFIED_BUFFER_DEPTH = 4096;

    logic clk, rst, enable;
    word_type runtime_count;
    word_type lower_instr_word, middle_instr_word;
    halfword_type upper_instr_word;
    logic [2:0] instr_write_enable;
    logic instr_fifo_empty, inst_fifo_full;
    byte_type [MATRIX_WIDTH-1:0] weight_write_port;
    weight_addr_type weight_addr;
    logic weight_enable;
    logic [MATRIX_WIDTH-1:0] weight_write_enable;
    byte_type [MATRIX_WIDTH-1:0] buffer_write_port, buffer_read_port;
    buffer_addr_type buffer_addr;
    logic buffer_enable;
    logic [MATRIX_WIDTH-1:0] buffer_write_enable;
    logic synchronize;

    instr_type instr;

    tpu #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
        .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .runtime_count(runtime_count),
        .lower_instr_word(lower_instr_word),
        .middle_instr_word(middle_instr_word),
        .upper_instr_word(upper_instr_word),
        .instr_write_enable(instr_write_enable),
        .instr_fifo_empty(instr_fifo_empty),
        .instr_fifo_full(instr_fifo_full),
        .weight_write_port(weight_write_port),
        .weight_addr(weight_addr),
        .weight_enable(weight_enable),
        .weight_write_enable(weight_write_enable),
        .buffer_write_port(buffer_write_port),
        .buffer_read_port(buffer_read_port),
        .buffer_addr(buffer_addr),
        .buffer_enable(buffer_enable),
        .buffer_write_enable(buffer_write_enable),
        .synchronize(synchronize)
    );

    assign lower_instr_word     = instr[4*BYTE_WIDTH-1:0];
    assign middle_instr_word    = instr[8*BYTE_WIDTH-1:4*BYTE_WIDTH];
    assign upper_instr_word     = instr[10*BYTE_WIDTH-1:8*BYTE_WIDTH];

    // clock signal generation
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialize input signals
        enable <= 0;
        rst <= 0;
        instr <= INIT_INSTR;
        instr_write_enable <= '{default: 0};
        weight_write_port <= '{default: 0};
        weight_addr <= '{default: 0};
        weight_enable <= 0;
        weight_write_enable <= 0;
        buffer_write_port <= '{default: 0};
        buffer_addr <= '{default: 0};
        buffer_enable <= 0;
        buffer_write_enable <= '{default: 0};

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // load weight
        @(posedge clk);
        enable <= 1;
        instr <= '{opcode: 8'b0000_1000, length: 14, buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_write_enable <= '{default: 1};

        // matrix multiply
        @(posedge clk);
        instr <= '{opcode: 8'b0010_0000, length: 14, buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_write_enable <= '{default: 1};

        // unsigned sigmoid activation
        @(posedge clk);
        instr <= '{opcode: 8'b1000_1001, length: 14, buffer_addr: 24'h00000E, acc_addr: 16'h0000};
        instr_write_enable <= '{default: 1};

        // synchronize
        @(posedge clk);
        instr <= '{opcode: 8'b1111_1111, length: 0, buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_write_enable <= '{default: 1};

        @(posedge clk);
        instr_write_enable <= '{default: 0};
    end
endmodule
