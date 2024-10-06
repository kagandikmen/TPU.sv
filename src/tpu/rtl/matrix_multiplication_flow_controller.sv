// Matrix multiplication flow controller
// Created: 2024-10-05
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/acc_load_ctr.sv"
`include "../rtl/dsp_ctr.sv"
`include "../rtl/dsp_load_ctr.sv"

import tpu_pkg::*;

module matrix_multiplication_flow_controller
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   instr_type instr,
        input   logic instr_enable,

        output  buffer_addr_type buffer_to_sds_addr,
        output  logic buffer_read_enable,
        output  logic mmu_sds_enable,
        output  logic is_mmu_signed,
        output  logic activate_weight,
        
        output  accumulator_addr_type acc_addr,
        output  logic accumulate,
        output  logic acc_enable,

        output  logic busy,
        output  logic resource_busy
    );

    logic buffer_read_en_cs = 0;
    logic buffer_read_en_ns;

    logic mmu_sds_en_cs = 0;
    logic mmu_sds_en_ns;

    logic [2:0] mmu_sds_delay_cs = '{default: 0};
    logic [2:0] mmu_sds_delay_ns;

    logic is_mmu_signed_cs = 0;
    logic is_mmu_signed_ns;

    logic [2:0] signed_pipe_cs = '{default: 0};
    logic [2:0] signed_pipe_ns;

    localparam WEIGHT_CTR_WIDTH = $clog2(MATRIX_WIDTH-1);
    logic [WEIGHT_CTR_WIDTH-1:0] weight_ctr_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_ctr_ns;

    logic [2:0] weight_pipe_cs = '{default: 0};
    logic [2:0] weight_pipe_ns;

    logic [2:0] activate_weight_delay_cs = '{default: 0};
    logic [2:0] activate_weight_delay_ns;

    logic acc_enable_cs = 0;
    logic acc_enable_ns;

    logic running_cs = 0;
    logic running_ns;

    logic [MATRIX_WIDTH+4:0] running_pipe_cs = '{default: 0};
    logic [MATRIX_WIDTH+4:0] running_pipe_ns;

    logic accumulate_cs = 0;
    logic accumulate_ns;

    buffer_addr_type buffer_addr_pipe_cs = '{default: 0};
    buffer_addr_type buffer_addr_pipe_ns;

    accumulator_addr_type acc_addr_pipe_cs = '{default: 0};
    accumulator_addr_type acc_addr_pipe_ns;

    logic [2:0] buffer_read_pipe_cs = '{default: 0};
    logic [2:0] buffer_read_pipe_ns;

    logic [2:0] mmu_sds_en_pipe_cs = '{default: 0};
    logic [2:0] mmu_sds_en_pipe_ns;

    logic [2:0] acc_en_pipe_cs = '{default: 0};
    logic [2:0] acc_en_pipe_ns;

    logic [2:0] accumulate_pipe_cs = '{default: 0};
    logic [2:0] accumulate_pipe_ns;

    logic acc_load;
    logic acc_rst;

    accumulator_addr_type [MATRIX_WIDTH+4:0] acc_addr_delay_cs = '{default: 0};
    accumulator_addr_type [MATRIX_WIDTH+4:0] acc_addr_delay_ns;

    logic [MATRIX_WIDTH+4:0] accumulate_delay_cs = '{default: 0};
    logic [MATRIX_WIDTH+4:0] accumulate_delay_ns;

    logic [MATRIX_WIDTH+4:0] acc_en_delay_cs = '{default: 0};
    logic [MATRIX_WIDTH+4:0] acc_en_delay_ns;

    // length_ctr signals
    logic length_rst;
    // logic length_end_val;
    logic length_load;
    logic length_event;

    // addr_ctr signals
    logic addr_load;

    // weight_ctr signals
    logic weight_rst;

    // counters
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

    acc_load_ctr #(
        .COUNTER_WIDTH(ACCUMULATOR_ADDR_WIDTH),
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) addr_ctr0 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(instr.acc_addr),
        .load(addr_load),
        .ctr_val(acc_addr_pipe_ns)        
    );

    dsp_load_ctr #(
        .COUNTER_WIDTH(BUFFER_ADDR_WIDTH)
    ) addr_ctr1 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(instr.buffer_addr),
        .load(addr_load),
        .ctr_val(buffer_addr_pipe_ns)
    );

    // pipeline
    assign accumulate_ns                    = instr.opcode[1];

    assign buffer_to_sds_addr               = buffer_addr_pipe_cs;
    assign acc_addr_delay_ns[0]             = acc_addr_pipe_cs;

    assign acc_addr                         = acc_addr_delay_cs[MATRIX_WIDTH+4];

    assign buffer_read_pipe_ns[2:1]         = buffer_read_pipe_cs[1:0];
    assign mmu_sds_en_pipe_ns[2:1]          = mmu_sds_en_pipe_cs[1:0];
    assign acc_en_pipe_ns[2:1]              = acc_en_pipe_cs[1:0];
    assign accumulate_pipe_ns[2:1]          = accumulate_pipe_cs[1:0];
    assign signed_pipe_ns[2:1]              = signed_pipe_cs[1:0];
    assign weight_pipe_ns[2:1]              = weight_pipe_cs[1:0];

    assign buffer_read_pipe_ns[0]           = buffer_read_en_cs;
    assign mmu_sds_en_pipe_ns[0]            = mmu_sds_en_cs;
    assign acc_en_pipe_ns[0]                = acc_enable_cs;
    assign accumulate_pipe_ns[0]            = accumulate_cs;
    assign signed_pipe_ns[0]                = is_mmu_signed_cs;
    assign weight_pipe_ns[0]                = (weight_ctr_cs == 0) ? 1 : 0;

    assign is_mmu_signed_ns                 = instr.opcode[0];

    assign buffer_read_enable               = (buffer_read_en_cs == 0) ? 0 : buffer_read_pipe_cs[2];
    assign mmu_sds_delay_ns[0]              = (mmu_sds_en_cs == 0) ? 0 : mmu_sds_en_pipe_cs[2];
    assign acc_en_delay_ns[0]               = (acc_enable_cs == 0) ? 0 : acc_en_pipe_cs[2];
    assign accumulate_delay_ns[0]           = (accumulate_cs == 0) ? 0 : accumulate_pipe_cs[2];

    assign is_mmu_signed                    = (mmu_sds_delay_cs[2] == 0) ? 0 : signed_pipe_cs[2];

    assign activate_weight_delay_ns[0]      = weight_pipe_cs[2];
    assign activate_weight_delay_ns[2:1]    = activate_weight_delay_cs[1:0];
    assign activate_weight                  = (mmu_sds_delay_cs[2] == 0) ? 0 : activate_weight_delay_cs[2];

    assign acc_enable                       = acc_en_delay_cs[MATRIX_WIDTH+4];
    assign accumulate                       = accumulate_delay_cs[MATRIX_WIDTH+4];
    assign mmu_sds_enable                   = mmu_sds_delay_cs[2];

    assign busy                                     = running_cs;
    assign running_pipe_ns[0]                       = running_cs;
    assign running_pipe_ns[MATRIX_WIDTH+4:1]        = running_pipe_cs[MATRIX_WIDTH+3:0];

    assign acc_addr_delay_ns[MATRIX_WIDTH+4:1]      = acc_addr_delay_cs[MATRIX_WIDTH+3:0];
    assign accumulate_delay_ns[MATRIX_WIDTH+4:1]    = accumulate_delay_cs[MATRIX_WIDTH+3:0];
    assign acc_en_delay_ns[MATRIX_WIDTH+4:1]        = acc_en_delay_cs[MATRIX_WIDTH+3:0];
    assign mmu_sds_delay_ns[2:1]                    = mmu_sds_delay_cs[1:0];

    // resource_busy logic
    always_comb
    begin
        logic resource_busy_temp;
        resource_busy_temp = running_cs;
        for(int i=0; i<MATRIX_WIDTH+5; i++)
        begin
            resource_busy_temp = resource_busy_temp || running_pipe_cs[i];
        end
        resource_busy = resource_busy_temp;
    end

    // weight counter logic
    always_comb
    begin
        if(weight_ctr_cs == $unsigned(MATRIX_WIDTH-1))
            weight_ctr_ns = '{default: 0};
        else
            weight_ctr_ns = $unsigned(weight_ctr_cs) + 1;
    end

    // control signals
    always_comb
    begin
        if(running_cs == 0)
        begin
            if(instr_enable == 1)
            begin
                running_ns          = 1;
                addr_load           = 1;
                buffer_read_en_ns   = 1;
                mmu_sds_en_ns       = 1;
                acc_enable_ns       = 1;
                length_load         = 1;
                length_rst          = 1;
                acc_load            = 1;
                acc_rst             = 0;
                weight_rst          = 1;
            end
            else
            begin
                running_ns          = 0; 
                addr_load           = 0; 
                buffer_read_en_ns   = 0; 
                mmu_sds_en_ns       = 0; 
                acc_enable_ns       = 0; 
                length_load         = 0; 
                length_rst          = 0; 
                acc_load            = 0; 
                acc_rst             = 0; 
                weight_rst          = 0; 
            end
        end
        else
        begin
            if(length_event == 1)
            begin
                running_ns          = 0; 
                addr_load           = 0; 
                buffer_read_en_ns   = 0; 
                mmu_sds_en_ns       = 0; 
                acc_enable_ns       = 0; 
                length_load         = 0; 
                length_rst          = 0; 
                acc_load            = 0; 
                acc_rst             = 1; 
                weight_rst          = 0; 
            end
            else
            begin
                running_ns          = 1;
                addr_load           = 0;
                buffer_read_en_ns   = 1;
                mmu_sds_en_ns       = 1;
                acc_enable_ns       = 1;
                length_load         = 0;
                length_rst          = 0;
                acc_load            = 0;
                acc_rst             = 0;
                weight_rst          = 0;
            end
        end
    end

    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            buffer_read_en_cs           <= 0; 
            mmu_sds_en_cs               <= 0; 
            acc_enable_cs               <= 0; 
            running_cs                  <= 0; 
            running_pipe_cs             <= '{default: 0};
            buffer_addr_pipe_cs         <= '{default: 0};
            acc_addr_pipe_cs            <= '{default: 0};
            acc_addr_delay_cs           <= '{default: 0};
            accumulate_delay_cs         <= '{default: 0};
            acc_en_delay_cs             <= '{default: 0};
            mmu_sds_delay_cs            <= '{default: 0};
            signed_pipe_cs              <= '{default: 0};
            weight_pipe_cs              <= '{default: 0};
            activate_weight_delay_cs    <= '{default: 0};
        end
        else if(enable)
        begin
            buffer_read_en_cs           <= buffer_read_en_ns;
            mmu_sds_en_cs               <= mmu_sds_en_ns;
            acc_enable_cs               <= acc_enable_ns;
            running_cs                  <= running_ns;
            running_pipe_cs             <= running_pipe_ns;
            buffer_addr_pipe_cs         <= buffer_addr_pipe_ns;
            acc_addr_pipe_cs            <= acc_addr_pipe_ns;
            acc_addr_delay_cs           <= acc_addr_delay_ns;
            accumulate_delay_cs         <= accumulate_delay_ns;
            acc_en_delay_cs             <= acc_en_delay_ns;
            mmu_sds_delay_cs            <= mmu_sds_delay_ns;
            signed_pipe_cs              <= signed_pipe_ns;
            weight_pipe_cs              <= weight_pipe_ns;
            activate_weight_delay_cs    <= activate_weight_delay_ns;
        end

        if(acc_rst)
        begin
            accumulate_cs       <= 0;
            buffer_read_pipe_cs <= '{default: 0};
            mmu_sds_en_pipe_cs  <= '{default: 0};
            acc_en_pipe_cs      <= '{default: 0};
            accumulate_pipe_cs  <= '{default: 0};
            is_mmu_signed_cs    <= 0;
        end
        else
        begin
            if(acc_load)
            begin
                accumulate_cs       <= accumulate_ns;
                is_mmu_signed_cs    <= is_mmu_signed_ns;
            end

            if(enable)
            begin
                buffer_read_pipe_cs <= buffer_read_pipe_ns;
                mmu_sds_en_pipe_cs  <= mmu_sds_en_pipe_ns;
                acc_en_pipe_cs      <= acc_en_pipe_ns;
                accumulate_pipe_cs  <= accumulate_pipe_ns;
            end
        end

        if(weight_rst)
            weight_ctr_cs   <= '{default: 0};
        else if(enable)
            weight_ctr_cs   <= weight_ctr_ns;
    end
endmodule
