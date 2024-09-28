// Testbench for runtime counter
// Created: 2024-09-29
// Modified: 2024-09-29

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module tb_runtime_ctr
    #(
    )(
    );

    logic clk, rst, instr_en, synch;
    word_type ctr_val;

    runtime_ctr #(
    ) dut (
        .clk(clk),
        .rst(rst),
        .instr_en(instr_en),
        .synch(synch),
        .ctr_val(ctr_val)
    );

    // clock generation
    initial
    begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialise
        rst         <= 0;
        instr_en    <= 0;
        synch       <= 0;

        // toggle reset
        repeat (2) @(posedge clk);
        rst <= 1;
        repeat (2) @(posedge clk);
        rst <= 0;
        repeat (2) @(posedge clk);

        // simulate running instructions
        instr_en <= 1;
        @(posedge clk);
        instr_en <= 0;
        repeat (32) @(posedge clk);
        instr_en <= 1;
        @(posedge clk);
        instr_en <= 0;
        repeat (32) @(posedge clk);

        // simulate synchronisation with the host
        synch <= 1;
        @(posedge clk);
        synch <= 0;
        
        // wrap up
        #10;
        $finish;
    end
endmodule
