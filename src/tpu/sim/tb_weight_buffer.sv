// Testbench for unified buffer
// Created: 2024-09-29
// Modified: 2024-09-29

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`include "../lib/tpu_pkg.sv"
`include "../rtl/weight_buffer.sv"

import tpu_pkg::*;

module tb_weight_buffer
    #(
    )(
    );

    localparam MATRIX_WIDTH = 4;
    localparam TILE_WIDTH = 16;

    logic clk, rst, enable, en0, en1, write_en0, write_en1;
    weight_addr_type addr0, addr1;
    byte_type [MATRIX_WIDTH-1:0] write_port0, read_port0, write_port1, read_port1;

    weight_buffer #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .TILE_WIDTH(TILE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .addr0(addr0),
        .en0(en0),
        .write_en0(write_en0),
        .write_port0(write_port0),
        .read_port0(read_port0),
        .addr1(addr1),
        .en1(en1),
        .write_en1(write_en1),
        .write_port1(write_port1),
        .read_port1(read_port1)
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
        // initialize signals
        rst         <= 0;
        enable      <= 1;
    
        addr0       <= 0;
        en0         <= 0;
        write_en0   <= 0;
        write_port0 <= 0;
        
        addr1       <= 0;
        en1         <= 0;
        write_en1   <= 0;
        write_port1 <= 0;

        // reset
        repeat (2) @(posedge clk);
        rst <= 1;
        repeat (2) @(posedge clk);
        rst <= 0;
        repeat (2) @(posedge clk);

        // test write through port 0
        en0 <= 1;
        write_en0 <= 1;
        for(int i=0; i<MATRIX_WIDTH*TILE_WIDTH; i++)
        begin
            addr0 <= i;
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                write_port0[j] <= i*j;
            end
            @(posedge clk);
        end
        en0 <= 0;
        write_en0 <= 0;

        repeat (2) @(posedge clk);

        // test read through port 0
        en0 <= 1;
        for(int i=0; i<TILE_WIDTH; i++)
        begin
            addr0 <= i;
            repeat (6) @(posedge clk);
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                #1;
                if(read_port0[j] != i*j)
                begin
                    $fatal("Error while reading through port 0 at time %0f (real: %0d, ideal %0d)", $realtime, read_port0[j], i*j);
                end
            end
        end
        en0 <= 0;

        @(posedge clk);

        // test write through port 1
        en1 <= 1;
        write_en1 <= 1;
        for(int i=0; i<MATRIX_WIDTH*TILE_WIDTH; i++)
        begin
            addr1 <= i;
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                write_port1[j] <= i*j+128;
            end
            @(posedge clk);
        end
        en1 <= 0;
        write_en1 <= 0;

        repeat (2) @(posedge clk);

        // test read through port 1
        en1 <= 1;
        for(int i=0; i<TILE_WIDTH; i++)
        begin
            addr1 <= i;
            repeat (6) @(posedge clk);
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                #1;
                if(read_port1[j] != i*j+128)
                begin
                    $fatal("Error while reading through port 1 at time %0f (real: %0d, ideal %0d)", $realtime, read_port1[j], i*j);
                end
            end
        end
        en1 <= 0;

        // wrap up
        $display("Tests completed successfully");
        #5;
        $finish;
    end

endmodule
