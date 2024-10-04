// Register file
// Created: 2024-10-03
// Modified: 2024-10-04

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module register_file
    #(
        parameter int MATRIX_WIDTH = 14,
        parameter int REGISTER_DEPTH = 512
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   accumulator_addr_type write_addr,
        input   word_type [MATRIX_WIDTH-1:0] data_in,
        input   logic write_enable,

        input   logic accumulate,

        input   accumulator_addr_type read_addr,
        output  word_type [MATRIX_WIDTH-1:0] data_out
    );

    logic [4*BYTE_WIDTH*MATRIX_WIDTH-1:0] accumulators [REGISTER_DEPTH-1:0];

    // memory port signals
    logic acc_write_en;
    accumulator_addr_type acc_write_addr, acc_read_addr, acc_accu_addr;
    word_type [MATRIX_WIDTH-1:0] acc_write_port, acc_read_port, acc_accumulate_port;

    // dsp signals
    word_type [MATRIX_WIDTH-1:0] dsp_add_port0_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] dsp_add_port0_ns;
    word_type [MATRIX_WIDTH-1:0] dsp_add_port1_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] dsp_add_port1_ns;
    word_type [MATRIX_WIDTH-1:0] dsp_result_port_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] dsp_result_port_ns;
    word_type [MATRIX_WIDTH-1:0] dsp_pipe0_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] dsp_pipe0_ns;
    word_type [MATRIX_WIDTH-1:0] dsp_pipe1_cs;
    word_type [MATRIX_WIDTH-1:0] dsp_pipe1_ns;
    
    // pipeline registers
    word_type [MATRIX_WIDTH-1:0] accumulate_port_pipe0_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] accumulate_port_pipe0_ns;
    word_type [MATRIX_WIDTH-1:0] accumulate_port_pipe1_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] accumulate_port_pipe1_ns;

    logic [2:0] accumulate_pipe_cs = '{default: 0};
    logic [2:0] accumulate_pipe_ns;

    word_type [MATRIX_WIDTH-1:0] write_port_pipe0_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] write_port_pipe0_ns;
    word_type [MATRIX_WIDTH-1:0] write_port_pipe1_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] write_port_pipe1_ns;
    word_type [MATRIX_WIDTH-1:0] write_port_pipe2_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] write_port_pipe2_ns;

    logic [5:0] write_enable_pipe_cs = '{default: 0};
    logic [5:0] write_enable_pipe_ns;

    accumulator_addr_type write_addr_pipe0_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe0_ns;
    accumulator_addr_type write_addr_pipe1_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe1_ns;
    accumulator_addr_type write_addr_pipe2_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe2_ns;
    accumulator_addr_type write_addr_pipe3_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe3_ns;
    accumulator_addr_type write_addr_pipe4_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe4_ns;
    accumulator_addr_type write_addr_pipe5_cs = '{default: 0};
    accumulator_addr_type write_addr_pipe5_ns;

    accumulator_addr_type read_addr_pipe0_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe0_ns;
    accumulator_addr_type read_addr_pipe1_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe1_ns;
    accumulator_addr_type read_addr_pipe2_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe2_ns;
    accumulator_addr_type read_addr_pipe3_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe3_ns;
    accumulator_addr_type read_addr_pipe4_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe4_ns;
    accumulator_addr_type read_addr_pipe5_cs = '{default: 0};
    accumulator_addr_type read_addr_pipe5_ns;

    // pipelines
    assign write_port_pipe0_ns = data_in;
    assign write_port_pipe1_ns = write_port_pipe0_cs;
    assign write_port_pipe2_ns = write_port_pipe1_cs;

    assign dsp_add_port0_ns = write_port_pipe2_cs;

    assign acc_write_port = dsp_result_port_cs;

    assign accumulate_port_pipe0_ns = acc_accumulate_port;
    assign accumulate_port_pipe1_ns = accumulate_port_pipe0_cs;

    assign accumulate_pipe_ns[2:1] = accumulate_pipe_cs[1:0];
    assign accumulate_pipe_ns[0] = accumulate;

    assign acc_accu_addr = write_addr;
    assign write_addr_pipe0_ns = write_addr;
    assign write_addr_pipe1_ns = write_addr_pipe0_cs;
    assign write_addr_pipe2_ns = write_addr_pipe1_cs;
    assign write_addr_pipe3_ns = write_addr_pipe2_cs;
    assign write_addr_pipe4_ns = write_addr_pipe3_cs;
    assign write_addr_pipe5_ns = write_addr_pipe4_cs;
    assign acc_write_addr = write_addr_pipe5_cs;

    assign write_enable_pipe_ns[5:1] = write_enable_pipe_cs[4:0];
    assign write_enable_pipe_ns[0] = write_enable;
    assign acc_write_en = write_enable_pipe_cs[5];

    assign read_addr_pipe0_ns = read_addr;
    assign read_addr_pipe1_ns = read_addr_pipe0_cs;
    assign read_addr_pipe2_ns = read_addr_pipe1_cs;
    assign read_addr_pipe3_ns = read_addr_pipe2_cs;
    assign read_addr_pipe4_ns = read_addr_pipe3_cs;
    assign read_addr_pipe5_ns = read_addr_pipe4_cs;
    assign acc_read_addr = read_addr_pipe5_cs;

    assign data_out = acc_read_port;

    assign dsp_pipe0_ns = dsp_add_port0_cs;
    assign dsp_pipe1_ns = dsp_add_port1_cs;


    // dsp add
    always_comb
    begin
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            dsp_result_port_ns[i] = $unsigned(dsp_pipe0_cs[i]) + $unsigned(dsp_pipe1_cs[i]);
        end
    end


    // accumulator mux
    always_comb
    begin
        if(accumulate_pipe_cs[2])
            dsp_add_port1_ns = accumulate_port_pipe1_cs;
        else
            dsp_add_port1_ns = '{default: 0};
    end


    // accumulator port 0
    always_ff @(posedge clk)
    begin
        if(enable)
        begin
            // synthesis translate_off
            if(acc_write_addr < REGISTER_DEPTH) 
            begin
            // synthesis translate_on
                if(acc_write_en)
                    accumulators[$unsigned(acc_write_addr)] <= acc_write_port;
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end


    // accumulator port 1
    always_ff @(posedge clk)
    begin
        if(enable)
        begin
            // synthesis translate_off
            if(acc_read_addr < REGISTER_DEPTH) 
            begin
            // synthesis translate_on
                acc_read_port <= accumulators[$unsigned(acc_read_addr)];
                acc_accumulate_port <= accumulators[$unsigned(acc_accu_addr)];
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end


    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            dsp_add_port0_cs <= '{default: 0};
            dsp_add_port1_cs <= '{default: 0};
            dsp_result_port_cs <= '{default: 0};
            dsp_pipe0_cs <= '{default: 0};
            dsp_pipe1_cs <= '{default: 0};

            accumulate_port_pipe0_cs <= '{default: 0};
            accumulate_port_pipe1_cs <= '{default: 0};

            accumulate_pipe_cs <= '{default: 0};

            write_port_pipe0_cs <= '{default: 0};
            write_port_pipe1_cs <= '{default: 0};
            write_port_pipe2_cs <= '{default: 0};

            write_enable_pipe_cs <= '{default: 0};

            write_addr_pipe0_cs <= '{default: 0};
            write_addr_pipe1_cs <= '{default: 0};
            write_addr_pipe2_cs <= '{default: 0};
            write_addr_pipe3_cs <= '{default: 0};
            write_addr_pipe4_cs <= '{default: 0};
            write_addr_pipe5_cs <= '{default: 0};

            read_addr_pipe0_cs <= '{default: 0};
            read_addr_pipe1_cs <= '{default: 0};
            read_addr_pipe2_cs <= '{default: 0};
            read_addr_pipe3_cs <= '{default: 0};
            read_addr_pipe4_cs <= '{default: 0};
            read_addr_pipe5_cs <= '{default: 0};
        end
        else if(enable)
        begin
            dsp_add_port0_cs <= dsp_add_port0_ns;
            dsp_add_port1_cs <= dsp_add_port1_ns;
            dsp_result_port_cs <= dsp_result_port_ns;
            dsp_pipe0_cs <= dsp_pipe0_ns;
            dsp_pipe1_cs <= dsp_pipe1_ns;

            accumulate_port_pipe0_cs <= accumulate_port_pipe0_ns;
            accumulate_port_pipe1_cs <= accumulate_port_pipe1_ns;

            accumulate_pipe_cs <= accumulate_pipe_ns;

            write_port_pipe0_cs <= write_port_pipe0_ns;
            write_port_pipe1_cs <= write_port_pipe1_ns;
            write_port_pipe2_cs <= write_port_pipe2_ns;

            write_enable_pipe_cs <= write_enable_pipe_ns;

            write_addr_pipe0_cs <= write_addr_pipe0_ns;
            write_addr_pipe1_cs <= write_addr_pipe1_ns;
            write_addr_pipe2_cs <= write_addr_pipe2_ns;
            write_addr_pipe3_cs <= write_addr_pipe3_ns;
            write_addr_pipe4_cs <= write_addr_pipe4_ns;
            write_addr_pipe5_cs <= write_addr_pipe5_ns;

            read_addr_pipe0_cs <= read_addr_pipe0_ns;
            read_addr_pipe1_cs <= read_addr_pipe1_ns;
            read_addr_pipe2_cs <= read_addr_pipe2_ns;
            read_addr_pipe3_cs <= read_addr_pipe3_ns;
            read_addr_pipe4_cs <= read_addr_pipe4_ns;
            read_addr_pipe5_cs <= read_addr_pipe5_ns;
        end
    end
endmodule
