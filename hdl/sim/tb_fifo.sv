// Testbench for FIFO unit
// Created: 2024-09-27
// Modified: 2024-09-27

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

module tb_fifo
    #(
    )(
    );

    localparam FIFO_DEPTH = 32;
    localparam FIFO_WIDTH = 8;

    logic clk, rst, write_en, next_en, empty, full;
    logic [FIFO_WIDTH-1:0] data_in, data_out;

    fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_WIDTH(FIFO_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
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
        rst         <= 0;
        data_in     <= 0;
        write_en    <= 0;
        next_en     <= 0;

        #5;

        // reset
        rst         <= 1;
        #5;
        rst         <= 0;
        
        #5;

        // fill fifo
        write_en <= 1;
        @(posedge clk);
        for(int i=0; i<FIFO_DEPTH; i++)
        begin   
            data_in <= i;
            @(posedge clk);
        end
        write_en <= 0;

        #5;

        // check if fifo is full
        if(!full)
        begin
            $fatal("FIFO should have been full");
        end

        #5;

        // iterate over written data and validate
        next_en <= 1;
        @(posedge clk);
        for(int i=0; i<FIFO_DEPTH; i++)
        begin
            #1;
            if(data_out != i)
            begin
                $fatal("Data read from address %0d of FIFO unsuccessful (real: %0d, ideal: %0d) at time %0f ns", i, data_out, i, $realtime);
            end
            @(posedge clk);
        end
        next_en <= 0;

        #5;

        // check if fifo is empty
        if(!empty)
        begin
            $fatal("FIFO should have been empty");
        end

        #5;

        $display("Tests were successful");
    end
endmodule
