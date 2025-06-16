// Look-ahead buffer
// Created:     2024-10-04
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module look_ahead_buffer
    #(
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   logic instr_busy,
        input   instr_type instr_in,
        input   logic instr_write,

        output  instr_type instr_out,
        output  logic instr_read
    );

    instr_type input_reg_cs = INIT_INSTR;
    instr_type input_reg_ns;

    logic input_write_cs = 0;
    logic input_write_ns;

    instr_type pipe_reg_cs = INIT_INSTR;
    instr_type pipe_reg_ns;

    logic pipe_write_cs = 0;
    logic pipe_write_ns;

    instr_type output_reg_cs = INIT_INSTR;
    instr_type output_reg_ns;

    logic output_write_cs = 0;
    logic output_write_ns;


    // input/output logic
    assign input_reg_ns = instr_in;
    assign instr_out = (instr_busy) ? INIT_INSTR : output_reg_cs;

    assign input_write_ns = instr_write;
    assign instr_read = (instr_busy) ? 0 : output_write_cs;


    // look-ahead
    always_comb
    begin
        if(pipe_write_cs)
        begin
            if(pipe_reg_cs.opcode[OPCODE_WIDTH-1:3] == 5'b00001)
            begin
                if(input_write_cs)
                begin
                    pipe_reg_ns     = input_reg_cs;
                    output_reg_ns   = pipe_reg_cs;
                    pipe_write_ns   = input_write_cs;
                    output_write_ns = pipe_write_cs;
                end
                else
                begin
                    pipe_reg_ns     = pipe_reg_cs;
                    output_reg_ns   = INIT_INSTR;
                    pipe_write_ns   = pipe_write_cs;
                    output_write_ns = 0;
                end
            end
            else
            begin
                pipe_reg_ns     = input_reg_cs;
                output_reg_ns   = pipe_reg_cs;
                pipe_write_ns   = input_write_cs;
                output_write_ns = pipe_write_cs;
            end
        end
        else
        begin
            pipe_reg_ns     = input_reg_cs;
            output_reg_ns   = pipe_reg_cs;
            pipe_write_ns   = input_write_cs;
            output_write_ns = pipe_write_cs;
        end
    end


    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            input_reg_cs    <= INIT_INSTR;
            pipe_reg_cs     <= INIT_INSTR;
            output_reg_cs   <= INIT_INSTR;
            input_write_cs  <= 0;
            pipe_write_cs   <= 0;
            output_write_cs <= 0;
        end
        else if(enable && !instr_busy)
        begin
            input_reg_cs    <= input_reg_ns;
            pipe_reg_cs     <= pipe_reg_ns;
            output_reg_cs   <= output_reg_ns;
            input_write_cs  <= input_write_ns;
            pipe_write_cs   <= pipe_write_ns;
            output_write_cs <= output_write_ns;
        end
    end
endmodule
