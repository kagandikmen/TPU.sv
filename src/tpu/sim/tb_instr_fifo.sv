// Testbench for instruction FIFO
// Created: 2024-09-28
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module tb_instr_fifo
    #(
    )(
    );

    localparam FIFO_DEPTH = 32;

    logic clk, rst, next_en, empty, full;
    logic [2:0] write_en;
    word_type lower_word, middle_word;
    halfword_type upper_word;
    instr_type data_out;

    instr_fifo #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .lower_word(lower_word),
        .middle_word(middle_word),
        .upper_word(upper_word),
        .write_en(write_en),
        .data_out(data_out),
        .next_en(next_en),
        .empty(empty),
        .full(full)
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

        // initialize
        rst <= 0;
        lower_word  <= 0;
        middle_word <= 0;
        upper_word  <= 0;
        write_en <= 0;
        next_en <= 0;

        // reset
        #5;
        rst <= 1;
        @(posedge clk);
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // put lower word inside fifo
        lower_word <= 'hAFFEDEAD;
        write_en[0] <= 1;
        @(posedge clk);
        lower_word <= 0;
        write_en[0] <= 0;

        #1;
        if(!empty)
        begin
            $fatal("FIFO should have been empty");
        end
        @(posedge clk);

        // put middle word inside fifo
        middle_word <= 'hDEADDEAD;
        write_en[1] <= 1;
        @(posedge clk);
        middle_word <= 0;
        write_en[1] <= 0;

        #1;
        if(!empty)
        begin
            $fatal("FIFO should have been empty");
        end
        @(posedge clk);

        // put upper word inside fifo
        upper_word <= 'hBA11;
        write_en[2] <= 1;
        @(posedge clk);
        upper_word <= 0;
        write_en[2] <= 0;

        @(posedge clk);
        #1;
        if(empty)
        begin
            $display("FIFO should not have been empty");
        end
        @(posedge clk);

        // read the instruction
        next_en <= 1;
        #1;
        if(data_out != bit_to_instr(80'hBA11DEADDEADAFFEDEAD))
        begin
            $display("Value read from FIFO does not match with the value put in");
        end

        $display("Tests completed successfully");

    end

endmodule
