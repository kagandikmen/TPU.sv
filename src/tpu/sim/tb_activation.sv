// Testbench for activation unit
// Created:     2024-10-03
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_activation
    #(
    )(
    );

    localparam MATRIX_WIDTH = 4;

    logic clk, rst, enable;
    activation_type activation_function;
    logic is_signed;
    word_type [MATRIX_WIDTH-1:0] data_in;
    byte_type [MATRIX_WIDTH-1:0] data_out;

    logic signed [7:0] byte_reg0_signed, byte_reg1_signed;
    logic signed [15:0] halfword_reg0_signed, halfword_reg1_signed;
    logic signed [31:0] word_reg0_signed, word_reg1_signed;

    logic [7:0] byte_reg0_unsigned, byte_reg1_unsigned;
    logic [15:0] halfword_reg0_unsigned, halfword_reg1_unsigned;
    logic [31:0] word_reg0_unsigned, word_reg1_unsigned;

    activation #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .activation_function(activation_function),
        .is_signed(is_signed),
        .data_in(data_in),
        .data_out(data_out)
    );

    // clock generation
    initial
    begin
        clk  = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialize signals
        rst         <= 0;
        enable      <= 0;
        is_signed   <= 0;
        data_in     <= '{default: 0};
        activation_function <= no_activation;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        
        @(posedge clk);
        enable <= 1;

        // test 1: signed sigmoid
        is_signed <= 1;
        activation_function <= sigmoid;
        word_reg0_signed = -2147483648;
        data_in = '{default: word_reg0_signed};                 // tests boundary
        @(posedge clk);
        data_in = '{default: $signed(-367289)};                 // tests middle area
        @(posedge clk);
        halfword_reg0_signed = -6;  halfword_reg1_signed = 0;   // tests boundary
        data_in = '{default: {halfword_reg0_signed, halfword_reg1_signed}};
        @(posedge clk);

        for(int i=-5; i<6; i++)                                 // test transition values
        begin
            for(int j=0; j<256; j++)
            begin
                halfword_reg0_signed = i;       byte_reg0_signed = j;       byte_reg1_signed = 0;
                data_in = '{default: {halfword_reg0_signed, byte_reg0_signed, byte_reg1_signed}};
                @(posedge clk);
            end
        end
        halfword_reg0_signed = 6;   halfword_reg1_unsigned = 0;
        data_in = '{default:{halfword_reg0_signed, halfword_reg1_unsigned}};
        @(posedge clk);
        word_reg0_signed = 8381865;
        data_in = '{default: word_reg0_signed};
        @(posedge clk);
        word_reg0_signed = 2147483647;
        data_in = '{default: word_reg0_signed};
        @(posedge clk);

        // test 2: unsigned sigmoid
        is_signed <= 0;
        activation_function <= sigmoid;
        
        for(int i=0; i<7; i++)                                  // test transition values
        begin
            for(int j=0; j<256; j++)
            begin
                halfword_reg0_unsigned = i;     byte_reg0_unsigned = j;     byte_reg1_unsigned = 0;
                data_in <= '{default: {halfword_reg0_unsigned, byte_reg0_unsigned, byte_reg1_unsigned}};
                @(posedge clk);
            end
        end
        halfword_reg0_unsigned = 7;     halfword_reg1_unsigned = 0;
        data_in = '{default: {halfword_reg0_unsigned, halfword_reg1_unsigned}};
        @(posedge clk);
        word_reg0_unsigned = 98235281;
        data_in = '{default: word_reg0_unsigned};
        @(posedge clk);
        word_reg0_unsigned = '{default: 1'b1};
        data_in = '{default: word_reg0_unsigned};
        @(posedge clk);

        // test 3: signed relu
        is_signed <= 1;
        activation_function <= relu;
        for(int i=-128; i<128; i++)
        begin
            for(int j=0; j<256; j++)
            begin
                halfword_reg0_signed = i;           byte_reg0_signed = j;
                data_in = '{default: {halfword_reg0_signed, byte_reg0_signed, 8'h00}};
                @(posedge clk);
            end
        end

        // test 4: unsigned relu
        is_signed <= 0;
        activation_function <= relu;
        for(int i=0; i<256; i++)
        begin
            for(int j=0; j<256; j++)
            begin
                halfword_reg0_unsigned = i;         byte_reg0_unsigned = j;
                data_in = '{default: {halfword_reg0_unsigned, byte_reg0_unsigned, 8'h00}};
                @(posedge clk);
            end
        end

        #5;
        $display("Tests completed");
        $finish;
    end 

endmodule
