// Testbench for dsp load counter
// Created: 2024-10-05
// Modified: 2024-10-05

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/dsp_load_ctr.sv"

import tpu_pkg::*;

module tb_dsp_load_ctr
    #(
    )(
    );

    localparam COUNTER_WIDTH = 32;
    
    logic clk, rst, enable, load;
    logic [COUNTER_WIDTH-1:0] start_val, ctr_val;

    dsp_load_ctr #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start_val(start_val),
        .load(load),
        .ctr_val(ctr_val)
    );

    // clock generation
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //stimuli
    initial
    begin
        // initialize signals
        rst <= 0;
        enable <= 0;
        start_val <= 0;
        load <= 0;

        // toggle reset
        repeat (2) @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // test 1: try incrementing without enabling
        @(posedge clk);
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat (3) @(posedge clk);
        if(ctr_val != 0)
            $fatal("Test 1.1 fails");
        @(posedge clk);
        load <= 1;
        start_val <= 5;
        @(posedge clk);
        load <= 0;
        repeat (3) @(posedge clk);
        if(ctr_val != 0)
            $fatal("Test 1.2 fails");

        // test 2: enable
        @(posedge clk);
        enable <= 1;
        repeat (2) @(posedge clk);
        for (int i=0; i<5; i++)
        begin
            #1;
            if(ctr_val != i)
                $fatal("Test 2 fails");
            @(posedge clk);
        end

        // test 3: load start_val
        @(posedge clk);
        load <= 1;
        start_val <= 11;
        @(posedge clk);
        load <= 0;
        repeat (3) @(posedge clk);
        if(ctr_val != 11)
            $fatal("Test 3 fails");
        
        @(posedge clk);
        enable <= 0;

        #50;
        $display("Tests completed successfully");
        $finish;
    end


endmodule
