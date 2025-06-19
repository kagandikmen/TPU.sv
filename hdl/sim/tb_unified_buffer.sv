// Testbench for unified buffer
// Created:     2024-09-28
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_unified_buffer
    #(
    )(
    );

    localparam MATRIX_WIDTH = 4;
    localparam TILE_WIDTH = 16;

    logic clk, rst, enable, master_en, en0, en1, write_en1;
    buffer_addr_type master_addr, addr0, addr1;
    logic [MATRIX_WIDTH-1:0] master_write_en;
    byte_type [MATRIX_WIDTH-1:0] master_write_port, master_read_port, read_port0, write_port1;

    unified_buffer #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .TILE_WIDTH(TILE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .master_addr(master_addr),
        .master_en(master_en),
        .master_write_en(master_write_en),
        .master_write_port(master_write_port),
        .master_read_port(master_read_port),
        .addr0(addr0),
        .en0(en0),
        .read_port0(read_port0),
        .addr1(addr1),
        .en1(en1),
        .write_en1(write_en1),
        .write_port1(write_port1)
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
        rst <= 0;
        enable <= 1;
        master_addr <= 0;
        master_en <= 0;
        master_write_en  <= 0;
        master_write_port <= 0;
    
        addr0 <= 0;
        en0 <= 0;
        
        addr1 <= 0;
        en1 <= 0;
        write_en1 <= 0;
        write_port1 <= 0;

        // reset
        repeat (2) @(posedge clk);
        rst <= 1;
        repeat (2) @(posedge clk);
        rst <= 0;
        repeat (2) @(posedge clk);

        // test write through port 0
        master_write_en <= '{default: 1};
        for(int i=0; i<MATRIX_WIDTH*TILE_WIDTH; i++)
        begin
            addr0 <= i;
            en0 <= 1;
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                master_write_port[j] <= i*j;
            end
            @(posedge clk);
        end
        en0 <= 0;
        master_write_en <= '{default: 0};

        // test read through port 0
        for(int i=0; i<TILE_WIDTH; i++)
        begin
            addr0 <= i;
            en0 <= 1;
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
        write_en1 <= 1;
        for(int i=0; i<MATRIX_WIDTH*TILE_WIDTH; i++)
        begin
            addr1 <= i;
            en1 <= 1;
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                write_port1[j] <= i*j+128;
            end
            @(posedge clk);
        end
        en1 <= 0;
        write_en1 <= 0;

        // test read through port 0
        for(int i=0; i<TILE_WIDTH; i++)
        begin
            addr0 <= i;
            en0 <= 1;
            repeat (6) @(posedge clk);
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                #1;
                if(read_port0[j] != i*j+128)
                begin
                    $fatal("Error while reading through port 0 at time %0f (real: %0d, ideal %0d)", $realtime, read_port0[j], i*j+128);
                end
            end
        end
        en0 <= 0;

        // wrap up
        $display("Tests completed successfully");
        #5;
        $finish;
    end

endmodule
