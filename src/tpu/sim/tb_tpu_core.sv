// Testbench for TPU's core
// Created: 2024-10-10
// Modified: 2024-10-11

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/tpu_core.sv"

import tpu_pkg::*;

module tb_tpu_core
    #(
    )(
    );

    localparam MATRIX_WIDTH = 14;

    logic clk, rst, enable;
    // byte_type [MATRIX_WIDTH-1:0] weight_write_port;
    // weight_addr_type weight_addr;
    // logic weight_enable;
    // logic [MATRIX_WIDTH-1:0] weight_write_enable;
    // byte_type [MATRIX_WIDTH-1:0] buffer_write_port, buffer_read_port;
    // buffer_addr_type buffer_addr;
    // logic buffer_enable;
    // logic [MATRIX_WIDTH-1:0] buffer_write_enable;
    instr_type instr_port;
    logic instr_enable, busy, synchronize;

    tpu_core #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .weight_write_port('{default: 0}),
        .weight_addr('{default: 0}),
        .weight_enable(0),
        .weight_write_enable('{default: 0}),
        .buffer_write_port('{default: 0}),
        .buffer_read_port(),
        .buffer_addr('{default: 0}),
        .buffer_enable(0),
        .buffer_write_enable('{default: 0}),
        .instr_port(instr_port),
        .instr_enable(instr_enable),
        .busy(busy),
        .synchronize(synchronize)
    );

    // clock signal
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialize signals
        enable <= 0;
        rst <= 0;
        instr_port <= INIT_INSTR;
        instr_enable <= 0;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        @(posedge clk);
        enable <= 1;
        instr_port <= '{opcode: 8'b0000_1001, length: $unsigned(14), buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_enable <= 1;

        @(posedge clk);
        instr_port <= '{opcode: 8'b0010_0001, length: $unsigned(14), buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_enable <= 1;

        @(posedge clk);
        instr_port <= '{opcode: 8'b1001_1001, length: $unsigned(14), buffer_addr: 24'h00000E, acc_addr: 16'h0000};
        instr_enable <= 1;

        @(posedge clk);
        instr_port <= '{opcode: 8'b1111_1111, length: $unsigned(0), buffer_addr: 24'h000000, acc_addr: 16'h0000};
        instr_enable <= 1;

        @(posedge clk);
        instr_enable <= 0;
    end
endmodule
