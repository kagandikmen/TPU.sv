// Testbench for register file
// Created:     2024-10-04
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_register_file
    #(
    )(
    );

    localparam MATRIX_WIDTH = 4;

    logic clk, rst, enable;
    accumulator_addr_type write_addr, read_addr;
    word_type [MATRIX_WIDTH-1:0] data_in, data_out;
    logic write_enable;
    logic accumulate;

    register_file #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .REGISTER_DEPTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .write_addr(write_addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .accumulate(accumulate),
        .read_addr(read_addr),
        .data_out(data_out)
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
        rst <= 0;
        enable <= 0;
        write_addr <= '{default: 0};
        data_in <= '{default: 0};
        write_enable <= 1;
        accumulate <= 0;
        read_addr <= '{default: 0};

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // set enable high
        @(posedge clk);
        enable <= 1;

        // test 1: hold values
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            for(int j=0; j<MATRIX_WIDTH; j++)
                data_in[j] <= $unsigned(i);
            write_addr <= $unsigned(i);
            write_enable <= 1;
            @(posedge clk);
        end
        write_enable <= 0;
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            read_addr <= $unsigned(i);
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                #1;
                if(data_out[j] != $unsigned(i))
                    $fatal("Test 1 failed at time: %0t ns", $realtime/1000); 
            end
            @(posedge clk);
        end

        // test 2: accumulate values
        accumulate <= 1;
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            for(int j=0; j<MATRIX_WIDTH; j++)
                data_in[j] <= $unsigned(j);
            write_addr <= $unsigned(i);
            write_enable <= 1;
            @(posedge clk);
        end
        write_enable <= 0;
        repeat (7) @(posedge clk);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            read_addr <= $unsigned(i);
            repeat (7) @(posedge clk);
            for(int j=0; j<MATRIX_WIDTH; j++)
            begin
                #1;
                if(data_out[j] != $unsigned(i+j))
                    $fatal("Test 2 failed at time: %0t ns", $realtime/1000);
            end
            @(posedge clk);
        end

        #5;
        $display("Tests completed successfully");
        $finish;
    end

endmodule
