// Testbench for matrix multiply unit controller
// Created: 2024-10-06
// Modified: 2024-10-06

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"
`include "../rtl/matrix_multiply_unit_controller.sv"

import tpu_pkg::*;

module tb_matrix_multiply_unit_controller
    #(
    )(
    );

    localparam MATRIX_WIDTH = 14;

    logic clk, rst, enable;
    instr_type instr;
    logic instr_enable;
    buffer_addr_type buffer_to_sds_addr;
    logic buffer_read_enable, mmu_sds_enable, is_mmu_signed, activate_weight;
    accumulator_addr_type acc_addr;
    logic accumulate, acc_enable;
    logic busy, resource_busy;

    matrix_multiply_unit_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .instr(instr),
        .instr_enable(instr_enable),
        .buffer_to_sds_addr(buffer_to_sds_addr),
        .buffer_read_enable(buffer_read_enable),
        .mmu_sds_enable(mmu_sds_enable),
        .is_mmu_signed(is_mmu_signed),
        .activate_weight(activate_weight),
        .acc_addr(acc_addr),
        .accumulate(accumulate),
        .acc_enable(acc_enable),
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

        // test 1
        enable <= 1;
        instr <= '{opcode: 8'b0010_0011, length: $unsigned(29), acc_addr: 16'h0049, buffer_addr: 24'h009463};
        instr_enable <= 1;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);

        // test 2
        wait (busy == 0);
        instr = '{opcode: 8'b0010_0000, length: $unsigned(14), acc_addr: 16'h0006, buffer_addr: 24'h0000AB};
        instr_enable = 1;
        @(posedge clk);
        instr_enable <= 0;
        @(posedge clk);

        wait (busy == 0);
        #50;
        $display("Tests completed");
        $finish;
    end
endmodule
