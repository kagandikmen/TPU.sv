// Runtime counter
// Created: 2024-09-29
// Modified: 2024-09-29

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module runtime_ctr
    #(
    )(
        input   logic clk,
        input   logic rst,
        
        input   logic instr_en,
        input   logic synch,
        output  word_type ctr_val
    );

    word_type ctr_cs = '{default: 0};
    word_type ctr_ns;

    word_type pipeline_cs = '{default: 0};
    word_type pipeline_ns;

    logic state_cs = 0;
    logic state_ns;

    logic rst_ctr;

    always_comb
    begin
        ctr_ns = ctr_cs + 1;
        pipeline_ns = ctr_cs;
        ctr_val = pipeline_cs;
    end

    // finite state machine
    always_comb
    begin
        case(state_cs)
        1'b0: begin
            case({instr_en, synch})
                2'b00: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
                2'b01: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
                2'b10: begin
                    state_ns <= 1;
                    rst_ctr <= 1;
                end
                2'b11: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
                default: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
            endcase
        end
        1'b1: begin
            case({instr_en, synch})
                2'b00: begin
                    state_ns <= 1;
                    rst_ctr <= 0;
                end
                2'b01: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
                2'b10: begin
                    state_ns <= 1;
                    rst_ctr <= 0;
                end
                2'b11: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
                default: begin
                    state_ns <= 0;
                    rst_ctr <= 0;
                end
            endcase
        end
        default: begin
            state_ns <= 0;
            rst_ctr <= 0;
        end
        endcase   
    end

    // state transition logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            state_cs <= 0;
            pipeline_cs <= 0;
        end
        else
        begin
            state_cs <= state_ns;
            pipeline_cs <= pipeline_ns;
        end

        if(rst_ctr)
        begin
            ctr_cs <= 0;
        end
        else
        begin
            if(state_cs)
                ctr_cs <= ctr_ns; 
        end
    end
endmodule
