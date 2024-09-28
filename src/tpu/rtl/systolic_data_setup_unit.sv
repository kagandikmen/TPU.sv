// Systolic data setup unit
// Created: 2024-09-28
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module systolic_data_setup_unit
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input logic clk,
        input logic rst,
        input logic enable,
        input byte_type [MATRIX_WIDTH-1:0] data_in,

        output byte_type [MATRIX_WIDTH-1:0] systolic_data_out
    );

    byte_type [MATRIX_WIDTH-1:1] buffer_reg_cs [MATRIX_WIDTH-1:1];
    byte_type [MATRIX_WIDTH-1:1] buffer_reg_ns [MATRIX_WIDTH-1:1];

    // shift logic
    always_comb
    begin
        for(int i=1; i<MATRIX_WIDTH; i++)
        begin
            for(int j=1; j<MATRIX_WIDTH; j++)
            begin
                if(i == 1)
                begin
                    buffer_reg_ns[i][j] = data_in[j];
                end
                else
                begin
                    buffer_reg_ns[i][j] = buffer_reg_cs[i-1][j];
                end
            end
        end
    end

    // output logic
    assign systolic_data_out[0] = data_in[0];
    
    always_comb
    begin
        for(int i=1; i<MATRIX_WIDTH; i++)
        begin
            systolic_data_out[i] = buffer_reg_cs[i][i];
        end
    end

    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
            buffer_reg_cs <= '{default: 0};
        else
        begin
            if(enable)
                buffer_reg_cs <= buffer_reg_ns;
        end
    end

endmodule
