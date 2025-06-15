// Accumulate load counter
// Created:     2024-10-05
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module acc_load_ctr
    #(
        parameter int COUNTER_WIDTH = 32,
        parameter int MATRIX_WIDTH = 14
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   logic [COUNTER_WIDTH-1:0] start_val,
        input   logic load,

        output  logic [COUNTER_WIDTH-1:0] ctr_val
    );

    logic [COUNTER_WIDTH-1:0] ctr_input_cs = '{default: 0};
    logic [COUNTER_WIDTH-1:0] ctr_input_ns;

    logic [COUNTER_WIDTH-1:0] start_val_cs = '{default: 0};
    logic [COUNTER_WIDTH-1:0] start_val_ns;

    logic [COUNTER_WIDTH-1:0] input_pipe_cs = '{default: 0};
    logic [COUNTER_WIDTH-1:0] input_pipe_ns;

    logic [COUNTER_WIDTH-1:0] ctr_cs = '{default: 0};
    (* use_dsp = "yes" *) logic [COUNTER_WIDTH-1:0] ctr_ns;

    logic load_cs = 0;
    logic load_ns;

    
    // pipeline
    assign load_ns = load;

    assign start_val_ns = start_val;
    
    assign input_pipe_ns = load ? start_val : {{COUNTER_WIDTH-1{1'b0}}, 1'b1};
    assign ctr_input_ns = input_pipe_cs;

    assign ctr_ns = (ctr_cs == $unsigned(MATRIX_WIDTH-1) + $unsigned(start_val_cs)) ? start_val_cs : ($unsigned(ctr_cs) + $unsigned(ctr_input_cs));
    assign ctr_val = ctr_cs;


    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            ctr_input_cs <= '{default: 0};
            input_pipe_cs <= '{default: 0};
            load_cs <= 0;
        end
        else if(enable)
        begin
            ctr_input_cs <= ctr_input_ns;
            input_pipe_cs <= input_pipe_ns;
            load_cs <= load_ns;
        end

        if(load_cs)
            ctr_cs <= '{default: 0};
        else if(enable)
            ctr_cs <= ctr_ns;

        if(load)
            start_val_cs <= start_val_ns;
    end
endmodule
