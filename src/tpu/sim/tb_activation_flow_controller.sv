// Activation flow controller
// Created: 2024-10-06
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/activation_flow_controller.sv"

import tpu_pkg::*;

module tb_activation_flow_controller
    #(
    )(
    );

    localparam MATRIX_WIDTH = 14;

    logic clk, rst, enable;
    instr_type instr;
    logic instr_enable;
    accumulator_addr_type acc_to_act_addr;
    activation_type activation_function;
    logic is_signed;
    buffer_addr_type act_to_buf_addr;
    logic buf_write_en, busy, resource_busy;

    activation_flow_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .instr(instr),
        .instr_enable(instr_enable),
        .acc_to_act_addr(acc_to_act_addr),
        .activation_function(activation_function),
        .is_signed(is_signed),
        .act_to_buf_addr(act_to_buf_addr),
        .buf_write_en(buf_write_en),
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
        instr <= INIT_INSTR;
        instr_enable <= 0;

        // toggle reset
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // test
        enable <= 1;
        instr <= '{opcode: 8'b1001_1001, length: $unsigned(5), acc_addr: 16'h0946, buffer_addr: 24'h000084};
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;

        // wrap up
        wait(busy == 0);
        #50;
        $display("Test completed");
        $finish;
    end
endmodule
