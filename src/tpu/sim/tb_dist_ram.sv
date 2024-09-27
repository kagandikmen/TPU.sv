// Testbench for distributed RAM
// Created: 2024-09-27
// Modified: 2024-09-27

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

module tb_dist_ram
    #(
        parameter int DATA_WIDTH = 8,
        parameter int DATA_DEPTH = 32,
        parameter int ADDRESS_WIDTH = 5
    )(
    );

    logic clk, write_en;
    logic [ADDRESS_WIDTH-1:0] in_addr, out_addr;
    logic [DATA_WIDTH-1:0] data_in, data_out;

    dist_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) dut (
        .clk(clk),
        .in_addr(in_addr),
        .data_in(data_in),
        .write_en(write_en),
        .out_addr(out_addr),
        .data_out(data_out)
    );

    // clock generation
    initial 
    begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // impulse generation
    initial 
    begin
        
        // test sequence begins

        in_addr = 0;
        data_in = 0;
        write_en = 0;
        out_addr = 0;

        #20;

        // write some data
        in_addr = 5'h01;
        data_in = 8'hAB;
        write_en = 1'b1;
        
        #5;

        // read the written data
        out_addr = 5'h01;

        // write some data
        in_addr = 5'h02;
        data_in = 8'hFE;

        #5;

        // read the written data
        out_addr = 5'h02;

        // try to write without enabling
        write_en = 1'b0;
        #5;
        in_addr = 5'h03;
        data_in = 8'hDE;
        #5;
        out_addr = 5'h03;

        // try to reread previously written data
        out_addr = 5'h01;
        #5;
        out_addr = 5'h02;
        #5;

        // write and read simultaneously
        write_en = 1'b1;
        in_addr = 5'h04;
        out_addr = 5'h04;
        data_in = 8'h33;

        // test sequence completed

    end

endmodule
