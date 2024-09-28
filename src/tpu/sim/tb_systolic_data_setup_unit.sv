// Testbench for systolic data setup unit
// Created: 2024-09-28
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module tb_systolic_data_setup_unit
    #(
    )(
    );

    localparam MATRIX_WIDTH = 10;

    logic clk, rst, enable;
    byte_type [MATRIX_WIDTH-1:0] data_in, systolic_data_out;

    byte_type [4:0] test_inputs [10] = '{
        '{0: 1,     1: 2,   2: 3,   3: 4,   4: 5}, 
        '{0: 6,     1: 7,   2: 8,   3: 9,   4: 10}, 
        '{0: 11,    1: 12,  2: 13,  3: 14,  4: 15}, 
        '{0: 16,    1: 17,  2: 18,  3: 19,  4: 20}, 
        '{0: 21,    1: 22,  2: 23,  3: 24,  4: 25}, 
        '{0: 26,    1: 27,  2: 28,  3: 29,  4: 30}, 
        '{0: 31,    1: 32,  2: 33,  3: 34,  4: 35}, 
        '{0: 36,    1: 37,  2: 38,  3: 39,  4: 40}, 
        '{0: 41,    1: 42,  2: 43,  3: 44,  4: 45}, 
        '{0: 46,    1: 47,  2: 48,  3: 49,  4: 50}
    };

    systolic_data_setup_unit #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .systolic_data_out(systolic_data_out)
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
        // initialise
        rst     <= 0;
        enable  <= 0;
        data_in <= 0;

        // toggle reset
        repeat (2) @(posedge clk);
        rst     <= 1;
        repeat (2) @(posedge clk);
        rst     <= 0;
        repeat (2) @(posedge clk);

        // test write/read
        enable <= 1;
        for(int i=0; i<5; i++)
        begin
            for(int j=0; j<10; j++)
            begin
                data_in[j] <= test_inputs[j][i];
            end
            @(posedge clk);
        end
    end

endmodule
