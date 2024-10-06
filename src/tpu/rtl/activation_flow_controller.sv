// Activation flow controller
// Created: 2024-10-06
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "dsp_ctr.sv"
`include "dsp_load_ctr.sv"

import tpu_pkg::*;

module activation_flow_controller
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   instr_type instr,
        input   logic instr_enable,

        output  accumulator_addr_type acc_to_act_addr,
        output  activation_type activation_function,
        output  logic is_signed,
        
        output  buffer_addr_type act_to_buf_addr,
        output  logic buf_write_en,

        output  logic busy,
        output  logic resource_busy
    );

    accumulator_addr_type acc_to_act_addr_cs = '{default: 0};
    accumulator_addr_type acc_to_act_addr_ns;

    buffer_addr_type act_to_buf_addr_cs = '{default: 0};
    buffer_addr_type act_to_buf_addr_ns;

    activation_type activation_function_cs = no_activation;
    activation_type activation_function_ns;

    logic is_signed_cs = 0;
    logic is_signed_ns;

    logic buf_write_en_cs = 0;
    logic buf_write_en_ns;

    logic running_cs = 0;
    logic running_ns;

    logic [MATRIX_WIDTH+14:0] running_pipe_cs ='{default: 0};
    logic [MATRIX_WIDTH+14:0] running_pipe_ns;

    logic act_load;
    logic act_rst;

    logic [2:0] buf_write_en_delay_cs = '{default: 0};
    logic [2:0] buf_write_en_delay_ns;
    
    logic [2:0] signed_delay_cs = '{default: 0};
    logic [2:0] signed_delay_ns;

    activation_type activation_pipe0_cs = no_activation;
    activation_type activation_pipe0_ns;

    activation_type activation_pipe1_cs = no_activation;
    activation_type activation_pipe1_ns;

    activation_type activation_pipe2_cs = no_activation;
    activation_type activation_pipe2_ns;

    // length_ctr signals
    logic length_rst;
    logic length_load;
    logic length_event;

    // addr_ctr signals
    logic addr_load;

    // delay register
    accumulator_addr_type [MATRIX_WIDTH+4:0] acc_addr_delay_cs = '{default: 0};
    accumulator_addr_type [MATRIX_WIDTH+4:0] acc_addr_delay_ns;

    activation_type [MATRIX_WIDTH+11:0] activation_delay_cs = '{default: no_activation};
    activation_type [MATRIX_WIDTH+11:0] activation_delay_ns;

    logic [MATRIX_WIDTH+11:0] is_signed_delay_cs = '{default: 0};
    logic [MATRIX_WIDTH+11:0] is_signed_delay_ns;

    buffer_addr_type [MATRIX_WIDTH+14:0] act_to_buf_delay_cs = '{default: 0};
    buffer_addr_type [MATRIX_WIDTH+14:0] act_to_buf_delay_ns;

    logic [MATRIX_WIDTH+14:0] write_en_delay_cs = '{default: 0};
    logic [MATRIX_WIDTH+14:0] write_en_delay_ns;

    // pipeline
    assign acc_addr_delay_ns[MATRIX_WIDTH+4:1]      = acc_addr_delay_cs[MATRIX_WIDTH+3:0];
    assign activation_delay_ns[MATRIX_WIDTH+11:1]   = activation_delay_cs[MATRIX_WIDTH+10:0];
    assign is_signed_delay_ns[MATRIX_WIDTH+11:1]    = is_signed_delay_cs[MATRIX_WIDTH+10:0];
    assign act_to_buf_delay_ns[MATRIX_WIDTH+14:1]   = act_to_buf_delay_cs[MATRIX_WIDTH+13:0];
    assign write_en_delay_ns[MATRIX_WIDTH+14:1]     = write_en_delay_cs[MATRIX_WIDTH+13:0];

    assign acc_to_act_addr      = acc_addr_delay_cs[MATRIX_WIDTH+4];
    assign activation_function  = activation_delay_cs[MATRIX_WIDTH+11];
    assign is_signed            = is_signed_delay_cs[MATRIX_WIDTH+11];
    assign act_to_buf_addr      = act_to_buf_delay_cs[MATRIX_WIDTH+14];
    assign buf_write_en         = write_en_delay_cs[MATRIX_WIDTH+14];

    dsp_ctr #(
        .COUNTER_WIDTH(LENGTH_WIDTH)
    ) length_ctr (
        .clk(clk),
        .rst(length_rst),
        .enable(enable),
        .end_val(instr.length),
        .load(length_load),
        .ctr_val(),
        .ctr_event(length_event)
    );

    dsp_load_ctr #(
        .COUNTER_WIDTH(ACCUMULATOR_ADDR_WIDTH)
    ) addr_ctr0 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(instr.acc_addr),
        .load(addr_load),
        .ctr_val(acc_to_act_addr_ns)
    );

    dsp_load_ctr #(
        .COUNTER_WIDTH(BUFFER_ADDR_WIDTH)
    ) addr_ctr1 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(instr.buffer_addr),
        .load(addr_load),
        .ctr_val(act_to_buf_addr_ns)
    );

    assign is_signed_ns             = instr.opcode[4];
    assign activation_function_ns   = instr.opcode[3:0];

    assign activation_delay_ns[0]   = (activation_function_cs == no_activation) ? no_activation : activation_pipe2_cs;
    assign is_signed_delay_ns[0]    = (is_signed_cs == 0) ? 0 : signed_delay_cs[2];
    assign write_en_delay_ns[0]     = (buf_write_en_cs == 0) ? 0 : buf_write_en_delay_cs[2];

    assign busy = running_cs;
    assign running_pipe_ns[0] = running_cs;
    assign running_pipe_ns[MATRIX_WIDTH+14:1] = running_pipe_cs[MATRIX_WIDTH+13:0];

    assign acc_addr_delay_ns[0] = acc_to_act_addr_cs;
    assign act_to_buf_delay_ns[0] = act_to_buf_addr_cs;

    assign buf_write_en_delay_ns[0]     = buf_write_en_cs;
    assign signed_delay_ns[0]           = is_signed_cs;
    assign activation_pipe0_ns          = activation_function_cs;
    assign buf_write_en_delay_ns[2:1]   = buf_write_en_delay_cs[1:0];
    assign signed_delay_ns[2:1]         = signed_delay_cs[1:0];
    assign activation_pipe1_ns          = activation_pipe0_cs;
    assign activation_pipe2_ns          = activation_pipe1_cs;

    // resource_busy output logic
    always_comb
    begin
        logic resource_busy_temp;
        resource_busy_temp = running_cs;
        for(int i=0; i<MATRIX_WIDTH+15; i++)
        begin
            resource_busy_temp = resource_busy_temp || running_pipe_cs[i];
        end
        resource_busy = resource_busy_temp;
    end

    // control signals
    always_comb
    begin
        if(running_cs == 0)
        begin
            if(instr_enable)
            begin
                running_ns      = 1;
                addr_load       = 1;
                buf_write_en_ns = 1;
                length_load     = 1;
                length_rst      = 1;
                act_load        = 1;
                act_rst         = 0;
            end
            else
            begin
                running_ns      = 0;
                addr_load       = 0;
                buf_write_en_ns = 0;
                length_load     = 0;
                length_rst      = 0;
                act_load        = 0;
                act_rst         = 0;
            end
        end
        else
        begin
            if(length_event)
            begin
                running_ns      = 0;
                addr_load       = 0;
                buf_write_en_ns = 0;
                length_load     = 0;
                length_rst      = 0;
                act_load        = 0;
                act_rst         = 1;
            end
            else
            begin
                running_ns      = 1;
                addr_load       = 0;
                buf_write_en_ns = 1;
                length_load     = 0;
                length_rst      = 0;
                act_load        = 0;
                act_rst         = 0;
            end
        end
    end

    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            buf_write_en_cs         = 0;
            running_cs              = 0;
            running_pipe_cs         = '{default: 0};
            acc_to_act_addr_cs      = '{default: 0};
            act_to_buf_addr_cs      = '{default: 0};
            buf_write_en_delay_cs   = '{default: 0};
            signed_delay_cs         = '{default: 0};
            activation_pipe0_cs     = no_activation;
            activation_pipe1_cs     = no_activation;
            activation_pipe2_cs     = no_activation;

            // delay register
            acc_addr_delay_cs       = '{default: 0};
            activation_delay_cs     = '{default: no_activation};
            is_signed_delay_cs      = '{default: 0};
            act_to_buf_delay_cs     = '{default: 0};
            write_en_delay_cs       = '{default: 0};
        end
        else if(enable)
        begin
            buf_write_en_cs         = buf_write_en_ns;
            running_cs              = running_ns;
            running_pipe_cs         = running_pipe_ns;
            acc_to_act_addr_cs      = acc_to_act_addr_ns;
            act_to_buf_addr_cs      = act_to_buf_addr_ns;
            buf_write_en_delay_cs   = buf_write_en_delay_ns;
            signed_delay_cs         = signed_delay_ns;
            activation_pipe0_cs     = activation_pipe0_ns;
            activation_pipe1_cs     = activation_pipe1_ns;
            activation_pipe2_cs     = activation_pipe2_ns;

            // delay register
            acc_addr_delay_cs       = acc_addr_delay_ns;
            activation_delay_cs     = activation_delay_ns;
            is_signed_delay_cs      = is_signed_delay_ns;
            act_to_buf_delay_cs     = act_to_buf_delay_ns;
            write_en_delay_cs       = write_en_delay_ns;
        end

        if(act_rst)
        begin
            activation_function_cs <= no_activation;
            is_signed_cs <= 0;
        end
        else if(act_load)
        begin
            activation_function_cs <= activation_function_ns;
            is_signed_cs <= is_signed_ns;
        end
    end
endmodule
