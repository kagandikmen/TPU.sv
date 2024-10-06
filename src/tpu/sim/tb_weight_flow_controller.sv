// Testbench for weight flow controller
// Created: 2024-10-06
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/weight_flow_controller.sv"

import tpu_pkg::*;

module tb_weight_flow_controller
    #(
    )(
    );

    localparam MATRIX_WIDTH = 14;

    logic clk, rst, enable;
    weight_instr_type instr;
    logic instr_enable, weight_read_enable;
    weight_addr_type weight_buffer_addr;
    logic load_weight;
    byte_type weight_addr;
    logic is_weight_signed, busy, resource_busy;

    weight_flow_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .instr(instr),
        .instr_enable(instr_enable),
        .weight_read_enable(weight_read_enable),
        .weight_buffer_addr(weight_buffer_addr),
        .load_weight(load_weight),
        .weight_addr(weight_addr),
        .is_weight_signed(is_weight_signed),
        .busy(busy),
        .resource_busy(resource_busy)
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
        enable <= 0;
        rst <= 0;
        instr <= INIT_WEIGHT_INSTR;
        instr_enable <= 0;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // test 1
        enable <= 1;
        instr <= '{opcode: 8'b0000_1001, length: $unsigned(15), weight_addr: 40'h00_0000_0021};
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);

        // test 2
        wait(busy == 0);
        instr <= '{opcode: 8'b0000_1000, length: $unsigned(14), weight_addr: 40'h00_0000_0081};
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);

        wait(busy == 0);
        #50;
        $display("Tests completed");
        $finish;
    end
endmodule
