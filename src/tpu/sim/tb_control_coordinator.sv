// Testbench for control coordinator
// Created: 2024-10-07
// Modified: 2024-10-08

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/control_coordinator.sv"

import tpu_pkg::*;

module tb_control_coordinator
    #(
    )(
    );

    logic clk, rst, enable;
    instr_type instr;
    logic instr_enable, busy, weight_busy, weight_resource_busy;
    weight_instr_type weight_instr;
    logic weight_instr_enable, matrix_busy, matrix_resource_busy;
    instr_type matrix_instr;
    logic matrix_instr_enable, activation_busy, activation_resource_busy;
    instr_type activation_instr;
    logic activation_instr_enable, synchronize;

    control_coordinator #(
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .instr(instr),
        .instr_enable(instr_enable),
        .busy(busy),
        .weight_busy(weight_busy),
        .weight_resource_busy(),
        .weight_instr(weight_instr),
        .weight_instr_enable(weight_instr_enable),
        .matrix_busy(matrix_busy),
        .matrix_resource_busy(),
        .matrix_instr(matrix_instr),
        .matrix_instr_enable(matrix_instr_enable),
        .activation_busy(activation_busy),
        .activation_resource_busy(),
        .activation_instr(activation_instr),
        .activation_instr_enable(activation_instr_enable),
        .synchronize(synchronize)
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
        instr <= INIT_INSTR;
        instr_enable <= 0;
        weight_busy <= 0;
        matrix_busy <= 0;
        activation_busy <= 0;

        // toggle reset
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // test weight
        enable <= 1;
        // test weight
        instr.opcode <= 8'b0000_1000;
        instr.length <= 32'h00000500; 
        instr.acc_addr <= 16'h0A30;
        instr_enable <= 1;
        weight_busy <= 0;
        matrix_busy <= 0;
        activation_busy <= 0;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);
        // test multiple weight
        weight_busy <= 1;
        repeat (2) @(posedge clk);
        instr.opcode <= 8'b0000_1000;
        instr.length <= 32'h00047100;
        instr.acc_addr <= 16'h0B30;
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        weight_busy <= 0;
        // test two weights in a row
        instr.length <= 32'h00000500;
        instr.acc_addr <= 16'h0A30;
        instr_enable <= 1;
        @(posedge clk);
        instr.length <= 32'h00095900;
        instr.acc_addr <= 16'h0CD0;
        @(posedge clk);
        weight_busy <= 1;
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        weight_busy <= 0;
        @(posedge clk);

        // test matrix
        instr.opcode <= 8'b0010_1000;
        instr.length <= 32'h00300000;
        instr.acc_addr <= 16'h0370;
        instr_enable <= 1;
        weight_busy <= 0;
        matrix_busy <= 0;
        activation_busy <= 0;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);
        // test multiple matrix
        matrix_busy <= 1;
        repeat (2) @(posedge clk);
        instr.opcode <= 8'b0010_0001;
        instr.length <= 32'h00047100;
        instr.acc_addr <= 16'h0B30;
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        matrix_busy <= 0;
        // test two matrices in a row
        instr.length <= 32'h00000500;
        instr.acc_addr <= 16'h0A30;
        instr_enable <= 1;
        @(posedge clk);
        instr.length <= 32'h00095900;
        instr.acc_addr <= 16'h0CD0;
        @(posedge clk);
        matrix_busy <= 1;
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        matrix_busy <= 0;

        // test activation
        instr.opcode <= 8'b1010_1000;
        instr.length <= 32'h00300000;
        instr.acc_addr <= 16'h0370;
        instr_enable <= 1;
        weight_busy <= 0;
        matrix_busy <= 0;
        activation_busy <= 0;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);
        // test multiple activation
        activation_busy <= 1;
        repeat (2) @(posedge clk);
        instr.opcode <= 8'b1000_0001;
        instr.length <= 32'h00047100;
        instr.acc_addr <= 16'h0B30;
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        activation_busy <= 0;
        // test two activations in a row
        instr.length <= 32'h00000500;
        instr.acc_addr <= 16'h0A30;
        instr_enable <= 1;
        @(posedge clk);
        instr.length <= 32'h00095900;
        instr.acc_addr <= 16'h0CD0;
        @(posedge clk);
        activation_busy <= 1;
        instr_enable <= 0;
        repeat (3) @(posedge clk);
        activation_busy <= 0;

        // test sequence weight->matrix->activation
        instr.opcode <= 8'b0000_1000;
        instr.length <= 32'h00300000;
        instr.acc_addr <= 16'h0370;
        instr_enable <= 1;
        weight_busy <= 0;
        matrix_busy <= 0;
        activation_busy <= 0;
        @(posedge clk);
        instr.opcode <= 8'b0010_0000;
        instr.length <= 32'h00000100;
        instr.acc_addr <= 16'h0A70;
        @(posedge clk);
        weight_busy <= 1;
        instr.opcode <= 8'b1000_0000;
        instr.length <= 32'h34000100;
        instr.acc_addr <= 16'hAFFE;
        @(posedge clk);
        matrix_busy <= 1;
        instr_enable <= 0;
        @(posedge clk);
        activation_busy <= 1;

        #100;
        $display("Tests completed");
        $finish;
    end
endmodule
