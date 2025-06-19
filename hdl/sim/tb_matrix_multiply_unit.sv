// Testbench for matrix multiply unit
// Created:     2024-10-01
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_matrix_multiply_unit
    #(
    )(
    );

    localparam MATRIX_WIDTH = 4;

    logic clk, rst, enable, weight_signed, systolic_signed, activate_weight, load_weight;
    byte_type [MATRIX_WIDTH-1:0] weight_data, systolic_data;
    byte_type weight_addr;
    word_type [MATRIX_WIDTH-1:0] result;

    const int input_matrix [3:0][3:0] = '{  '{ 40,  76,  19, 192}, 
                                            '{  3,  84,  12,   8},
                                            '{ 54,  18, 255, 120},
                                            '{ 30,  84, 122,   2}   };

    const int weight_matrix [3:0][3:0] = '{ '{ 13,  89, 178,   9}, 
                                            '{ 84, 184, 245,  18},
                                            '{255,  73,  14,   3},
                                            '{ 98, 212,  78,  29}   };

    const int result_matrix [3:0][3:0] = '{ '{30565, 59635, 40982,  7353}, 
                                            '{10939, 18295, 21906,  1807},
                                            '{78999, 52173, 26952,  5055},
                                            '{38752, 27456, 27784,  2206}   };

    const int input_matrix_signed [3:0][3:0] = '{   '{ 74,  91,  64,  10}, 
                                                    '{  5,  28,  26,   9},
                                                    '{ 56,   9,  72, 127},
                                                    '{ 94,  26,  92,   8}   };

    const int weight_matrix_signed [3:0][3:0] = '{  '{ -13,  89,  92,   9}, 
                                                    '{ -84, 104,  86,  18},
                                                    '{-128,  73,  14,   3},
                                                    '{ -98, 127,  78,  29}  };

    const int result_matrix_signed [3:0][3:0] = '{  '{-17778,  21992,  16310,   2786}, 
                                                    '{ -6627,   6398,   3934,    888},
                                                    '{-23146,  27305,  16840,   4565},
                                                    '{-15966,  18802,  12796,   1822}   };
    
    int current_input [MATRIX_WIDTH-1:0][MATRIX_WIDTH-1:0];
    int current_result [MATRIX_WIDTH-1:0][MATRIX_WIDTH-1:0];
    logic current_sign;
    boolean start = false; 
    boolean evaluate = false;

    matrix_multiply_unit #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .weight_data(weight_data),
        .weight_signed(weight_signed),
        .systolic_data(systolic_data),
        .systolic_signed(systolic_signed),
        .activate_weight(activate_weight),
        .load_weight(load_weight),
        .weight_addr(weight_addr),
        .result(result)
    );

    // clock generation
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    task load_weights (input int matrix [MATRIX_WIDTH-1:0][MATRIX_WIDTH-1:0], input logic is_signed);
        
            // initiate signals
        start               <= false;
        rst                 <= 0;
        enable              <= 0;
        weight_data         <= 0;
        weight_signed       <= 0;
        systolic_data       <= 0;
        systolic_signed     <= 0;
        activate_weight     <= 0;
        load_weight         <= 0;
        weight_addr         <= 0;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        weight_signed <= is_signed;

        // load address 0
        weight_addr <= $unsigned(0);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            weight_data[i] <= matrix[0][i];
        end
        load_weight <= 1;
        @(posedge clk);

        // load address 1
        weight_addr <= $unsigned(1);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            weight_data[i] <= matrix[1][i];
        end
        load_weight <= 1;
        @(posedge clk);

        // load address 2
        weight_addr <= $unsigned(2);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            weight_data[i] <= matrix[2][i];
        end
        load_weight <= 1;
        @(posedge clk);

        // load address 3
        weight_addr <= $unsigned(3);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            weight_data[i] <= matrix[3][i];
        end
        load_weight <= 1;
        @(posedge clk);

        //////////////////

        load_weight     <= 0;
        weight_signed   <= 0;
        activate_weight <= 1;
        enable          <= 1;

        //////////////////

        start           <= true;
        @(posedge clk);
        start           <= false;
        activate_weight <= 0;
        repeat (12) @(posedge clk);

    endtask

    initial
    begin
        current_sign    <= 0;
        current_input   <= input_matrix;
        current_result  <= result_matrix;
        load_weights(weight_matrix, 0);

        current_sign    <= 1;
        current_input   <= input_matrix_signed;
        current_result  <= result_matrix_signed;
        load_weights(weight_matrix_signed, 1);

        $finish;
    end

    always @(*)
    begin
        evaluate <= false;
        @(start == true);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            systolic_data[0] <= current_input[i][0];
            @(posedge clk);
        end
        systolic_data[0] <= 0;
        evaluate <= true;
        @(posedge clk);
        evaluate <= false;
    end

    always @(*)
    begin
        @(start == true);
        @(posedge clk);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            systolic_data[1] <= current_input[i][1];
            @(posedge clk);
        end
        systolic_data[1] <= 0;
    end

    always @(*)
    begin
        @(start == true);
        repeat (2) @(posedge clk);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            systolic_data[2] <= current_input[i][2];
            @(posedge clk);
        end
        systolic_data[2] <= 0;
    end

    always @(*)
    begin
        systolic_signed <= 0;
        @(start == true);
        systolic_signed <= current_sign;
        repeat (3) @(posedge clk);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            systolic_data[3] <= current_input[i][3];
            @(posedge clk);
            systolic_signed <= 0;
        end
        systolic_data[3] <= 0;
    end

    always @(evaluate == true)
    begin
        repeat (2) @(posedge clk);
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            @(posedge clk);

            if(result[0] != current_result[i][0])
                $fatal("Test 0 failed (real: %0d, ideal: %0d) at time %0t ns", result[0], current_result[i][0], $realtime/1000);

            if(result[1] != current_result[i][1])
                $fatal("Test 1 failed (real: %0d, ideal: %0d) at time %0t ns", result[1], current_result[i][1], $realtime/1000);

            if(result[2] != current_result[i][2])
                $fatal("Test 2 failed (real: %0d, ideal: %0d) at time %0t ns", result[2], current_result[i][2], $realtime/1000);

            if(result[3] != current_result[i][3])
                $fatal("Test 3 failed (real: %0d, ideal: %0d) at time %0t ns", result[3], current_result[i][3], $realtime/1000);

        end
        
        $display("Test completed successfully");
    end

endmodule
