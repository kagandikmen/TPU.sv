// Matrix multiply unit
// Created:     2024-10-01
// Modified:    2025-06-16

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module matrix_multiply_unit
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   byte_type [MATRIX_WIDTH-1:0] weight_data,
        input   logic weight_signed,
        input   byte_type [MATRIX_WIDTH-1:0] systolic_data,
        input   logic systolic_signed,

        input   logic activate_weight,
        input   logic load_weight,
        input   byte_type weight_addr,

        output  word_type [MATRIX_WIDTH-1:0] result
    );

    word_type [MATRIX_WIDTH-1:0] interim_result [MATRIX_WIDTH-1:0];

    logic [MATRIX_WIDTH-1:0] load_weight_map;

    logic [MATRIX_WIDTH-2:0] activate_ctrl_cs = 0;
    logic [MATRIX_WIDTH-2:0] activate_ctrl_ns;
    logic [MATRIX_WIDTH-1:0] activate_map;

    extended_byte_type [MATRIX_WIDTH-1:0] extended_weight_data;
    extended_byte_type [MATRIX_WIDTH-1:0] extended_systolic_data;

    logic [MATRIX_WIDTH+1:0] sign_ctrl_cs = 0;
    logic [MATRIX_WIDTH+1:0] sign_ctrl_ns;


    // linear shift register
    assign activate_ctrl_ns[MATRIX_WIDTH-2:1] = activate_ctrl_cs[MATRIX_WIDTH-3:0];
    assign activate_ctrl_ns[0] = activate_weight;

    assign sign_ctrl_ns[MATRIX_WIDTH+1:1] = sign_ctrl_cs[MATRIX_WIDTH:0];
    assign sign_ctrl_ns[0] = systolic_signed;

    assign activate_map = {activate_ctrl_cs, activate_ctrl_ns[0]};


    // address conversion
    always_comb
    begin
        load_weight_map = 0;
        if(load_weight)
            load_weight_map[weight_addr] = 1;
    end


    // sign extension
    always_comb
    begin
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            if(weight_signed)
                extended_weight_data[i] = {weight_data[i][BYTE_WIDTH-1], weight_data[i]};
            else
                extended_weight_data[i] = {1'b0, weight_data[i]};

            if(sign_ctrl_ns[i])
                extended_systolic_data[i] = {systolic_data[i][BYTE_WIDTH-1], systolic_data[i]};
            else
                extended_systolic_data[i] = {1'b0, systolic_data[i]};
        end
    end


    // mac units
    genvar i, j;
    generate
        for(i=0; i<MATRIX_WIDTH; i++)
        begin
            for(j=0; j<MATRIX_WIDTH; j++)
            begin
                if(i==0)
                begin
                    mac_unit #(
                        .LAST_SUM_WIDTH(2),
                        .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH)
                    ) mac_firstcolumn (
                        .clk(clk),
                        .rst(rst),
                        .enable(enable),
                        .weight_in(extended_weight_data[j]),
                        .preload_weight(load_weight_map[i]),
                        .load_weight(activate_map[i]),
                        .data_in(extended_systolic_data[i]),
                        .last_sum('b0),
                        .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH-1:0])
                    );
                end
                else if(i>0 && i<=2*(BYTE_WIDTH-1))
                begin
                    mac_unit #(
                        .LAST_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i-1),
                        .PARTIAL_SUM_WIDTH(2*EXTENDED_BYTE_WIDTH+i)
                    ) mac_fullcolumn (
                        .clk(clk),
                        .rst(rst),
                        .enable(enable),
                        .weight_in(extended_weight_data[j]),
                        .preload_weight(load_weight_map[i]),
                        .load_weight(activate_map[i]),
                        .data_in(extended_systolic_data[i]),
                        .last_sum(interim_result[i-1][j][2*EXTENDED_BYTE_WIDTH+i-2:0]),
                        .partial_sum(interim_result[i][j][2*EXTENDED_BYTE_WIDTH+i-1:0])
                    );
                end
                else if(i>2*(BYTE_WIDTH-1))
                begin
                    mac_unit #(
                        .LAST_SUM_WIDTH(4*BYTE_WIDTH),
                        .PARTIAL_SUM_WIDTH(4*BYTE_WIDTH)
                    ) mac_cuttedcolumn (
                        .clk(clk),
                        .rst(rst),
                        .enable(enable),
                        .weight_in(extended_weight_data[j]),
                        .preload_weight(load_weight_map[i]),
                        .load_weight(activate_map[i]),
                        .data_in(extended_systolic_data[i]),
                        .last_sum(interim_result[i-1][j]),
                        .partial_sum(interim_result[i][j])
                    );
                end 
            end
        end
    endgenerate


    // result assignment
    // assign result = interim_result[MATRIX_WIDTH-1];
    always @(*)
    begin
        logic [4*BYTE_WIDTH-1 : 2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-1] extend_v;
        for(int i=0; i<MATRIX_WIDTH; i++)
        begin
            if(sign_ctrl_cs[MATRIX_WIDTH+1])
                extend_v = '{default: interim_result[MATRIX_WIDTH-1][i][2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-2]};
            else
                extend_v = '{default: 0};
            result[i] = {extend_v, interim_result[MATRIX_WIDTH-1][i][2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-2 : 0]};
        end
    end


    // next state logic
    always_ff @(posedge clk)
    begin
        activate_ctrl_cs    <= activate_ctrl_ns;
        sign_ctrl_cs        <= sign_ctrl_ns;
        
        if(rst)  
        begin
            activate_ctrl_cs    <= 0;
            sign_ctrl_cs        <= 0;
        end
    end
endmodule
