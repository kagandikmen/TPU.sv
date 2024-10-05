// Dsp counter
// Created: 2024-10-05
// Modified: 2024-10-05

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module dsp_ctr
    #(
        parameter int COUNTER_WIDTH = 32
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   logic [COUNTER_WIDTH-1:0] end_val,
        input   logic load,

        output  logic [COUNTER_WIDTH-1:0] ctr_val,
        output  logic ctr_event
    );

    (* use_dsp = "yes" *) logic [COUNTER_WIDTH-1:0] ctr ='{default: 0};
    logic [COUNTER_WIDTH-1:0] end_reg = '{default: 0};

    logic event_cs = 0;
    logic event_ns;

    logic event_pipe_cs = 0;
    logic event_pipe_ns;


    // pipeline
    assign ctr_val = ctr;
    assign ctr_event = event_pipe_cs;
    assign event_pipe_ns = event_cs;


    // check
    always_comb
    begin
        if(ctr == end_reg)
            event_ns = 1;
        else
            event_ns = 0;
    end


    // next state logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            ctr <= '{default: 0};
            event_cs <= 0;
            event_pipe_cs <= 0;
        end
        else if(enable)
        begin
            ctr <= $unsigned(ctr) + 1;
            event_cs <= event_ns;
            event_pipe_cs <= event_pipe_ns;
        end

        if(load)
            end_reg <= end_val;
    end
endmodule
