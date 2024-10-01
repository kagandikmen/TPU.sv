// Multiply-accumulate unit
// Created: 2024-09-30
// Modified: 2024-10-01

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module mac_unit
    #(
        parameter int LAST_SUM_WIDTH = 0,
        parameter int PARTIAL_SUM_WIDTH = 2*EXTENDED_BYTE_WIDTH
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,
        
        input   extended_byte_type weight_in,
        input   logic preload_weight,
        input   logic load_weight,

        input   extended_byte_type data_in,
        input   logic [LAST_SUM_WIDTH-1:0] last_sum,

        output  logic [PARTIAL_SUM_WIDTH-1:0] partial_sum
    );

    extended_byte_type preweight_cs = 0;
    extended_byte_type preweight_ns;

    extended_byte_type weight_cs = 0;
    extended_byte_type weight_ns;

    extended_byte_type data_in_cs = 0;
    extended_byte_type data_in_ns;

    mul_halfword_type pipeline_cs = 0;
    mul_halfword_type pipeline_ns;

    logic [PARTIAL_SUM_WIDTH-1:0] partial_sum_cs = 0;
    logic [PARTIAL_SUM_WIDTH-1:0] partial_sum_ns;

    // assign inputs to their dedicated registers
    always_comb
    begin
        data_in_ns      = data_in;
        preweight_ns    = weight_in;
        weight_ns       = preweight_cs;
        pipeline_ns     = data_in_cs * weight_cs;
    end

    // output logic
    generate
        if((LAST_SUM_WIDTH > 0) && (LAST_SUM_WIDTH < PARTIAL_SUM_WIDTH))
        begin
            always_comb
                partial_sum_ns  = pipeline_cs + last_sum;
        end
        else if((LAST_SUM_WIDTH > 0) && (LAST_SUM_WIDTH == PARTIAL_SUM_WIDTH))
        begin
            always_comb
                partial_sum_ns  = pipeline_cs + last_sum;
        end  
        else
        begin
            always_comb
                partial_sum_ns  = pipeline_cs;
        end
    endgenerate

    assign partial_sum     = partial_sum_cs;

    // next state logic
    always_ff @(posedge clk)
    begin
        preweight_cs        <= preweight_cs;
        weight_cs           <= weight_cs;
        data_in_cs          <= data_in_cs;
        pipeline_cs         <= pipeline_cs;
        partial_sum_cs      <= partial_sum_cs;
        
        if(rst)
        begin
            preweight_cs    <= 0;
            weight_cs       <= 0;
            data_in_cs      <= 0;
            pipeline_cs     <= 0;
            partial_sum_cs  <= 0;
        end
        else
        begin
            if(preload_weight)
                preweight_cs    <= preweight_ns;

            if(load_weight)
                weight_cs       <= weight_ns;

            if(enable)
            begin
                data_in_cs      <= data_in_ns;
                pipeline_cs     <= pipeline_ns;
                partial_sum_cs  <= partial_sum_ns;
            end 
        end
    end
endmodule
