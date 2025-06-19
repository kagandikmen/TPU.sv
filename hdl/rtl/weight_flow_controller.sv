// Weight flow controller
// Created:     2024-10-06
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module weight_flow_controller
    #(
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   weight_instr_type instr,
        input   logic instr_enable,

        output  logic weight_read_enable,
        output  weight_addr_type weight_buffer_addr,

        output  logic load_weight,
        output  byte_type weight_addr,

        output  logic is_weight_signed,

        output  logic busy,
        output  logic resource_busy
    );

    logic weight_read_en_cs = 0;
    logic weight_read_en_ns;

    logic [2:0] load_weight_cs = '{default: 0};
    logic [2:0] load_weight_ns;

    logic is_weight_signed_cs = 0;
    logic is_weight_signed_ns;

    logic [2:0] signed_pipe_cs = '{default: 0};
    logic [2:0] signed_pipe_ns;

    logic signed_load;
    logic signed_rst;

    localparam WEIGHT_CTR_WIDTH = $clog2(MATRIX_WIDTH-1);
    logic [WEIGHT_CTR_WIDTH-1:0] weight_addr_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_addr_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe0_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe0_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe1_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe1_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe2_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe2_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe3_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe3_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe4_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe4_ns;

    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe5_cs = '{default: 0};
    logic [WEIGHT_CTR_WIDTH-1:0] weight_pipe5_ns;

    weight_addr_type buffer_pipe_cs = '{default: 0};
    weight_addr_type buffer_pipe_ns;

    logic read_pipe0_cs = 0;
    logic read_pipe0_ns;

    logic read_pipe1_cs = 0;
    logic read_pipe1_ns;

    logic read_pipe2_cs = 0;
    logic read_pipe2_ns;

    logic running_cs = 0;
    logic running_ns;

    logic [2:0] running_pipe_cs = '{default: 0};
    logic [2:0] running_pipe_ns;

    // length_ctr signals
    logic length_rst;
    logic length_load;
    logic length_event;

    // addr_ctr signals
    logic addr_load;

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
        .COUNTER_WIDTH(WEIGHT_ADDR_WIDTH)
    ) addr_ctr (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(instr.weight_addr),
        .load(addr_load),
        .ctr_val(buffer_pipe_ns)
    );

    // pipeline
    assign read_pipe0_ns        = weight_read_en_cs;
    assign read_pipe1_ns        = read_pipe0_cs;
    assign read_pipe2_ns        = read_pipe1_cs;
    assign weight_read_enable   = (weight_read_en_cs == 0) ? 0 : read_pipe2_cs;
    
        // weight buffer read takes 3 clock cycles
    assign load_weight_ns[0]    = (weight_read_en_cs == 0) ? 0 : read_pipe2_cs;
    assign load_weight_ns[2:1]  = load_weight_cs[1:0];
    assign load_weight          = load_weight_cs[2];

    assign is_weight_signed_ns  = instr.opcode[0];
    assign signed_pipe_ns[0]    = is_weight_signed_cs;
    assign signed_pipe_ns[2:1]  = signed_pipe_cs[1:0];
    assign is_weight_signed     = (load_weight_cs[2] == 0) ? 0 : signed_pipe_cs[2];

    assign weight_pipe0_ns      = weight_addr_cs;
    assign weight_pipe1_ns      = weight_pipe0_cs;
    assign weight_pipe2_ns      = weight_pipe1_cs;
    assign weight_pipe3_ns      = weight_pipe2_cs;
    assign weight_pipe4_ns      = weight_pipe3_cs;
    assign weight_pipe5_ns      = weight_pipe4_cs;
    assign weight_addr[WEIGHT_CTR_WIDTH-1:0] = weight_pipe5_cs;
    assign weight_addr[BYTE_WIDTH-1:WEIGHT_CTR_WIDTH] = '{default: 0};

    assign weight_buffer_addr   = buffer_pipe_cs;

    assign busy                 = running_cs;
    assign running_pipe_ns[0]   = running_cs;
    assign running_pipe_ns[2:1] = running_pipe_cs[1:0];

    // resource_busy output logic
    always_comb
    begin
        logic resource_busy_temp;
        resource_busy_temp = running_cs;
        for(int i=0; i<3; i++)
        begin
            resource_busy_temp = resource_busy_temp || running_pipe_cs[i];
        end
        resource_busy = resource_busy_temp;
    end

    // weight address counter logic
    always_comb
    begin
        if(weight_addr_cs == $unsigned(MATRIX_WIDTH-1))
            weight_addr_ns = '{default: 0};
        else
            weight_addr_ns = $unsigned(weight_addr_cs) + 1;
    end
    
    // synthesis translate_off
    always_ff @(posedge clk)
    begin
        if(instr_enable && running_cs)
            $warning("New instruction beeing feeden while still processing at time %0t", $realtime);
    end
    // synthesis translate_on

    // control signals
    always_comb
    begin
        if(!running_cs)
        begin
            if(instr_enable)
            begin
                running_ns          = 1;
                addr_load           = 1;
                weight_read_en_ns   = 1;
                length_load         = 1;
                length_rst          = 1;
                signed_load         = 1;
                signed_rst          = 0;
            end
            else
            begin
                running_ns          = 0;
                addr_load           = 0;
                weight_read_en_ns   = 0;
                length_load         = 0;
                length_rst          = 0;
                signed_load         = 0;
                signed_rst          = 0;
            end
        end
        else
        begin
            if(length_event)
            begin
                running_ns          = 0;
                addr_load           = 0;
                weight_read_en_ns   = 0;
                length_load         = 0;
                length_rst          = 0;
                signed_load         = 0;
                signed_rst          = 1;
            end
            else
            begin
                running_ns          = 1;
                addr_load           = 0;
                weight_read_en_ns   = 1;
                length_load         = 0;
                length_rst          = 0;
                signed_load         = 0;
                signed_rst          = 0;
            end
        end
    end

    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            weight_read_en_cs   <= 0;
            load_weight_cs      <= '{default: 0};
            running_cs          <= 0;
            running_pipe_cs     <= '{default: 0};
            weight_pipe0_cs     <= '{default: 0};
            weight_pipe1_cs     <= '{default: 0};
            weight_pipe2_cs     <= '{default: 0};
            weight_pipe3_cs     <= '{default: 0};
            weight_pipe4_cs     <= '{default: 0};
            weight_pipe5_cs     <= '{default: 0};
            buffer_pipe_cs      <= '{default: 0};
            signed_pipe_cs      <= '{default: 0};
        end
        else if(enable)
        begin
            weight_read_en_cs   <= weight_read_en_ns;
            load_weight_cs      <= load_weight_ns;
            running_cs          <= running_ns;
            running_pipe_cs     <= running_pipe_ns;
            weight_pipe0_cs     <= weight_pipe0_ns;
            weight_pipe1_cs     <= weight_pipe1_ns;
            weight_pipe2_cs     <= weight_pipe2_ns;
            weight_pipe3_cs     <= weight_pipe3_ns;
            weight_pipe4_cs     <= weight_pipe4_ns;
            weight_pipe5_cs     <= weight_pipe5_ns;
            buffer_pipe_cs      <= buffer_pipe_ns;
            signed_pipe_cs      <= signed_pipe_ns;
        end

        if(length_rst)
            weight_addr_cs  <= '{default: 0};
        else if(enable)
            weight_addr_cs  <= weight_addr_ns;

        if(signed_rst)
        begin
            is_weight_signed_cs <= 0;
            read_pipe0_cs       <= 0;
            read_pipe1_cs       <= 0;
            read_pipe2_cs       <= 0;
        end
        else
        begin
            if(signed_load)
                is_weight_signed_cs <= is_weight_signed_ns;

            if(enable)
            begin
                read_pipe0_cs   <= read_pipe0_ns;
                read_pipe1_cs   <= read_pipe1_ns;
                read_pipe2_cs   <= read_pipe2_ns;
            end
        end
    end
endmodule
