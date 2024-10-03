// Activation unit
// Created: 2024-10-03
// Modified: 2024-10-03

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module activation
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,
        
        input   activation_type activation_function,
        input   logic is_signed,

        input   word_type [MATRIX_WIDTH-1:0] data_in,
        output  word_type [MATRIX_WIDTH-1:0] data_out
    );

    const int SIGMOID_UNSIGNED  [0:164]     = '{128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,157,159,161,163,165,167,169,170,172,174,176,177,179,181,182,184,186,187,189,190,192,193,195,196,198,199,200,202,203,204,206,207,208,209,210,212,213,214,215,216,217,218,219,220,221,222,223,224,225,225,226,227,228,229,229,230,231,232,232,233,234,234,235,235,236,237,237,238,238,239,239,240,240,241,241,241,242,242,243,243,243,244,244,245,245,245,246,246,246,246,247,247,247,248,248,248,248,248,249,249,249,249,250,250,250,250,250,250,251,251,251,251,251,251,252,252,252,252,252,252,252,252,253,253,253,253,253,253,253,253,253,253,253,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254};
    const int SIGMOID_SIGNED    [-88:70]    = '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,6,6,6,7,7,8,8,9,9,10,10,11,12,12,13,14,14,15,16,17,18,19,20,21,22,23,25,26,27,29,30,31,33,34,36,38,39,41,43,45,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80,82,83,85,87,89,90,92,94,95,97,98,99,101,102,103,105,106,107,108,109,110,111,112,113,114,114,115,116,116,117,118,118,119,119,120,120,121,121,122,122,122,123,123,123,124,124,124,124,124,125,125,125,125,125,126,126,126,126,126,126,126,126};

    word_type [MATRIX_WIDTH-1:0] input_reg_cs = '{default: 0};
    word_type [MATRIX_WIDTH-1:0] input_reg_ns;

    byte_type [MATRIX_WIDTH-1:0] input_pipe0_cs = '{default: 0};
    byte_type [MATRIX_WIDTH-1:0] input_pipe0_ns;

    logic [3*BYTE_WIDTH-1:0] relu_round_reg_cs [MATRIX_WIDTH-1:0] = '{default: 'b0};
    logic [3*BYTE_WIDTH-1:0] relu_round_reg_ns [MATRIX_WIDTH-1:0];

    logic [20:0] sigmoid_round_reg_cs [MATRIX_WIDTH-1:0] = '{default: 20'b0};
    logic [20:0] sigmoid_round_reg_ns [MATRIX_WIDTH-1:0];

    byte_type [MATRIX_WIDTH-1:0] relu_out;
    byte_type [MATRIX_WIDTH-1:0] sigmoid_out;

    byte_type [MATRIX_WIDTH-1:0] output_reg_cs = '{default: 0};
    byte_type [MATRIX_WIDTH-1:0] output_reg_ns;

    activation_type activation_function_reg0_cs = no_activation;
    activation_type activation_function_reg0_ns;
    activation_type activation_function_reg1_cs = no_activation;
    activation_type activation_function_reg1_ns;

    logic [1:0] is_signed_reg_cs = '{default: 0};
    logic [1:0] is_signed_reg_ns;


    // rounding
    assign input_reg_ns = data_in;
    always_comb
    begin
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            input_pipe0_ns[i] = input_reg_cs[i][4*BYTE_WIDTH-1:3*BYTE_WIDTH];
            relu_round_reg_ns[i] = $unsigned(input_reg_cs[i][4*BYTE_WIDTH-1:BYTE_WIDTH]) + input_reg_cs[i][BYTE_WIDTH-1];

            if(is_signed_reg_cs[0])
                sigmoid_round_reg_ns[i] = {$unsigned(input_reg_cs[i][4*BYTE_WIDTH-1:2*BYTE_WIDTH-4]) + input_reg_cs[i][2*BYTE_WIDTH-5], 1'b0};
            else
                sigmoid_round_reg_ns[i] = $unsigned(input_reg_cs[i][4*BYTE_WIDTH-1:2*BYTE_WIDTH-5]) + input_reg_cs[i][2*BYTE_WIDTH-6];
        end
    end


    // prelude to activation
    assign activation_function_reg0_ns  = activation_function;
    assign activation_function_reg1_ns  = activation_function_reg0_cs;

    assign is_signed_reg_ns[0] = is_signed;
    assign is_signed_reg_ns[1] = is_signed_reg_cs[0]; 


    // relu activation
    always_comb
    begin
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            if(is_signed_reg_cs[1])
            begin
                if($signed(relu_round_reg_cs[i]) < 0)
                    relu_out[i] = '{default: 0};
                else if($signed(relu_round_reg_cs[i]) > 127)
                    relu_out[i] = $signed(127);
                else
                    relu_out[i] = relu_round_reg_cs[i][BYTE_WIDTH-1:0];
            end
            else
            begin
                if($unsigned(relu_round_reg_cs[i]) > 255)
                    relu_out[i] = $unsigned(255);
                else
                    relu_out[i] = relu_round_reg_cs[i][BYTE_WIDTH-1:0];
            end
        end
    end


    // sigmoid activation
    always_comb
    begin
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            if(is_signed_reg_cs[1])
            begin
                if($signed(sigmoid_round_reg_cs[i][20:1]) < -88)
                    sigmoid_out[i] = '{default: 0};
                else if($signed(sigmoid_round_reg_cs[i][20:1]) > 70)
                    sigmoid_out[i] = $signed(127);
                else
                    sigmoid_out[i] = $signed(SIGMOID_SIGNED[$signed(sigmoid_round_reg_cs[i][20:1])]);
            end
            else
            begin
                if($unsigned(sigmoid_round_reg_cs[i]) > 164)
                    sigmoid_out[i] = $unsigned(255);
                else
                    sigmoid_out[i] = $unsigned(SIGMOID_UNSIGNED[$unsigned(sigmoid_round_reg_cs[i])]);
            end
        end
    end


    // activation selection
    always_comb
    begin
        case(activation_function_reg1_cs)
            relu:           output_reg_ns = relu_out;
            sigmoid:        output_reg_ns = sigmoid_out;
            no_activation:  output_reg_ns = input_pipe0_cs;
            default:        
            begin
                $error("Unknown activation function");
                output_reg_ns = input_pipe0_cs;
            end
        endcase
    end


    // output logic
    assign data_out = '{default: output_reg_cs};


    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            output_reg_cs               = '{default: 0};
            input_reg_cs                = '{default: 0};
            input_pipe0_cs              = '{default: 0};
            relu_round_reg_cs           = '{default: 0};
            sigmoid_round_reg_cs        = '{default: 0};
            is_signed_reg_cs            = '{default: 0};
            activation_function_reg0_cs = no_activation;
            activation_function_reg1_cs = no_activation;
        end
        else if(enable)
        begin
            output_reg_cs               = output_reg_ns;
            input_reg_cs                = input_reg_ns;
            input_pipe0_cs              = input_pipe0_ns;
            relu_round_reg_cs           = relu_round_reg_ns;
            sigmoid_round_reg_cs        = sigmoid_round_reg_ns;
            is_signed_reg_cs            = is_signed_reg_ns;
            activation_function_reg0_cs = activation_function_reg0_ns;
            activation_function_reg1_cs = activation_function_reg1_ns;
        end
    end

endmodule
