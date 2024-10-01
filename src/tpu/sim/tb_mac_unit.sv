// Testbench for multiply-accumulate unit
// Created: 2024-09-30
// Modified: 2024-10-01

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`include "../lib/tpu_pkg.sv"
`include "../rtl/mac_unit.sv"

import tpu_pkg::*;

module tb_mac_unit
    #(
    )(
    );

    localparam LAST_SUM_WIDTH       = 6;
    localparam PARTIAL_SUM_WIDTH    = 16;

    logic clk, rst, enable, preload_weight, load_weight;
    logic [LAST_SUM_WIDTH-1:0] last_sum;
    logic [PARTIAL_SUM_WIDTH-1:0] partial_sum;
    extended_byte_type weight_in, data_in;

    logic result_now;

    mac_unit #(
        .LAST_SUM_WIDTH(LAST_SUM_WIDTH),
        .PARTIAL_SUM_WIDTH(PARTIAL_SUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .weight_in(weight_in),
        .preload_weight(preload_weight),
        .load_weight(load_weight),
        .data_in(data_in),
        .last_sum(last_sum),
        .partial_sum(partial_sum)
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
        result_now      <= 0;
        enable          <= 0;
        preload_weight  <= 0;
        load_weight     <= 0;
        rst             <= 0;
        weight_in       <= 0;
        data_in         <= 0;
        last_sum        <= 0;

        // toggle reset
        @(posedge clk);
        rst             <= 1;
        @(posedge clk);
        rst             <= 0;

        for(int input_val=0; input_val<64; input_val++)
        begin
            for(int last_val=0; last_val<64; last_val++)
            begin
                for(int weight=0; weight<64; weight++)
                begin
                    enable          <= 0;
                    weight_in       <= $unsigned(weight);
                    preload_weight  <= 1;
                    @(posedge clk);
                    load_weight     <= 1;
                    preload_weight  <= 0;
                    @(posedge clk);
                    enable          <= 1;
                    data_in         <= $unsigned(input_val);
                    load_weight     <= 0;
                    preload_weight  <= ~preload_weight;
                    @(posedge clk);
                    last_sum        <= $unsigned(last_val);
                    repeat(2) @(posedge clk);
                    result_now      <= 1;
                    #1;
                    // check the result
                    if(partial_sum != ($unsigned(weight) * $unsigned(input_val) + $unsigned(last_val)))
                        $display("Result incorrect (real: %0d, ideal: %0d)", partial_sum, $unsigned(weight) + $unsigned(last_val) + $unsigned(input_val));
                    @(posedge clk);
                    result_now      <= 0;
                end
            end
        end

        $display("Tests completed successfully");
        #5;
        $finish;
    end
endmodule
