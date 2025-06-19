// Testbench for dsp counter
// Created:     2024-10-05
// Modified:    2025-06-15

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`ifdef TEROSHDL
    `include "../lib/tpu_pkg.sv"
`endif

import tpu_pkg::*;

module tb_dsp_ctr 
    #(
    )(
    );

    localparam COUNTER_WIDTH = 6;

    logic clk, rst, enable, load, ctr_event;
    logic [COUNTER_WIDTH-1:0] end_val, ctr_val;

    dsp_ctr #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .end_val(end_val),
        .load(load),
        .ctr_val(ctr_val),
        .ctr_event(ctr_event)
    );

    // clock generation
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // stimuli
    initial
    begin
        // initialize signals
        rst <= 0;
        enable <= 0;
        end_val <= 0;
        load <= 0;

        // toggle reset
        repeat (2) @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // test 1: try incrementing without setting enable high
        @(posedge clk);
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat (5) @(posedge clk);
        if(ctr_val != 0)
            $fatal("Test 1 failed");

        // test 2: enable with load
        @(posedge clk);
        enable <= 1;
        end_val <= 15;
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat (14) @(posedge clk); 
        if(ctr_val != 14)
            $fatal("Test 2 failed");

        // test 3: test ctr_event flag
        @(posedge clk);
        repeat (2) @(posedge clk);
        if(ctr_event != 1)
            $fatal("Test 3.1 failed");
        @(posedge clk);
        if(ctr_event != 0)
            $fatal("Test 3.2 failed");

        #50;
        $display("Tests completed successfully");
        $finish;
    end

endmodule
