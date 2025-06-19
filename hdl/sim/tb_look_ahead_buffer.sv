// Testbench for look-ahead buffer
// Created:     2024-10-04
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_look_ahead_buffer
    #(
    )(
    );

    logic clk, rst, enable;
    logic instr_busy, instr_write, instr_read;
    instr_type instr_in, instr_out;

    look_ahead_buffer #(
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .instr_busy(instr_busy),
        .instr_in(instr_in),
        .instr_write(instr_write),
        .instr_out(instr_out),
        .instr_read(instr_read)
    );

    // clock generation
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialize signals
        rst     <= 0;
        enable  <= 0;
        instr_busy  <= 0;
        instr_in    <= INIT_INSTR;
        instr_write <= 0;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // set enable high
        enable <= 1;
        @(posedge clk);

        // write instructions in
        instr_in.opcode <= 8'b00001000;
        instr_write <= 1;
        @(posedge clk);
        instr_write <= 0;
        repeat (3) @(posedge clk);

        instr_in.opcode <= 8'b00100000;
        instr_write <= 1;
        @(posedge clk);

        instr_in.opcode <= 8'b10000000;
        @(posedge clk);

        instr_in.opcode <= 8'b00100000;
        @(posedge clk);
        instr_busy <= 1;
        instr_write <= 0;

        repeat (4) @(posedge clk);
        instr_busy <= 0;

        #50;
        $display("Test generation completed");
        $finish;
    end
endmodule
