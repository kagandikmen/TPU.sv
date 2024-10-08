// Control coordinator
// Created: 2024-10-07
// Modified: 2024-10-07

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module control_coordinator
    #(
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   instr_type instr,
        input   logic instr_enable,

        output  logic busy,

        input   logic weight_busy,
        input   logic weight_resource_busy,
        output  weight_instr_type weight_instr,
        output  logic weight_instr_enable,

        input   logic matrix_busy,
        input   logic matrix_resource_busy,
        output  instr_type matrix_instr,
        output  logic matrix_instr_enable,

        input   logic activation_busy,
        input   logic activation_resource_busy,
        output  instr_type activation_instr,
        output  logic activation_instr_enable,

        output  logic synchronize
    );

    logic [3:0] en_flags_cs = '{default: 0};
    logic [3:0] en_flags_ns;

    instr_type instr_cs = INIT_INSTR;
    instr_type instr_ns;

    logic instr_enable_cs = 0;
    logic instr_enable_ns;

    logic instr_running;

    // pipeline
    assign instr_ns = instr;
    assign instr_enable_ns = instr_enable;
    assign busy = instr_running;

    // decode
    always_comb
    begin
        if(instr.opcode == 8'hFF)
            en_flags_ns = 4'b1000;
        else if(instr.opcode[7] == 1)
            en_flags_ns = 4'b0100;
        else if(instr.opcode[5] == 1)
            en_flags_ns = 4'b0010;
        else if(instr.opcode[3] == 1)
            en_flags_ns = 4'b0001;
        else    // probably nop
            en_flags_ns = 4'b0000;
    end

    // running detect
    always_comb
    begin
        if(instr_enable_cs)
        begin
            if(en_flags_cs[3])
            begin
                if(weight_resource_busy || matrix_resource_busy || activation_resource_busy)
                begin
                    instr_running           = 1;
                    weight_instr_enable     = 0;
                    matrix_instr_enable     = 0;
                    activation_instr_enable = 0;
                    synchronize             = 0;
                end
                else
                begin
                    instr_running           = 0;
                    weight_instr_enable     = 0;
                    matrix_instr_enable     = 0;
                    activation_instr_enable = 0;
                    synchronize             = 1;
                end
            end
            else
            begin
                if((weight_busy && en_flags_cs[0]) || (matrix_busy && (en_flags_cs[1] || en_flags_cs[2])) || (activation_busy && en_flags_cs[2]))
                begin
                    instr_running           = 1;
                    weight_instr_enable     = 0;
                    matrix_instr_enable     = 0;
                    activation_instr_enable = 0;
                    synchronize             = 0;
                end
                else
                begin
                    instr_running           = 0;
                    weight_instr_enable     = en_flags_cs[0];
                    matrix_instr_enable     = en_flags_cs[1];
                    activation_instr_enable = en_flags_cs[2];
                    synchronize             = 0;
                end
            end
        end
        else
        begin
            instr_running           = 0;
            weight_instr_enable     = 0;
            matrix_instr_enable     = 0;
            activation_instr_enable = 0;
            synchronize             = 0;
        end
    end

    assign weight_instr     = instr_cs;
    assign matrix_instr     = instr_cs;
    assign activation_instr = instr_cs;

    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            en_flags_cs     <= '{default: 0};
            instr_cs        <= INIT_INSTR;
            instr_enable_cs <= 0;
        end
        else if(!instr_running && enable)
        begin
            en_flags_cs     <= en_flags_ns;
            instr_cs        <= instr_ns;
            instr_enable_cs <= instr_enable_ns;
        end 
    end
endmodule
