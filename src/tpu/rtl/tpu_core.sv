// TPU's core
// Created:     2024-10-08
// Modified:    2025-06-08

// Copyright (c) 2024-2025 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

`include "weight_buffer.sv"
`include "unified_buffer.sv"
`include "systolic_data_setup_unit.sv"
`include "matrix_multiply_unit.sv"
`include "register_file.sv"
`include "activation.sv"
`include "weight_flow_controller.sv"
`include "matrix_multiplication_flow_controller.sv"
`include "activation_flow_controller.sv"
`include "look_ahead_buffer.sv"
`include "control_coordinator.sv"

import tpu_pkg::*;

module tpu_core
    #(
        parameter int MATRIX_WIDTH          = 14,
        parameter int WEIGHT_BUFFER_DEPTH   = 32768,
        parameter int UNIFIED_BUFFER_DEPTH  = 4096
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        input   byte_type [MATRIX_WIDTH-1:0] weight_write_port,
        input   weight_addr_type weight_addr,
        input   logic weight_enable,
        input   logic [MATRIX_WIDTH-1:0] weight_write_enable,

        input   byte_type [MATRIX_WIDTH-1:0] buffer_write_port,
        output  byte_type [MATRIX_WIDTH-1:0] buffer_read_port,
        input   buffer_addr_type buffer_addr,
        input   logic buffer_enable,
        input   logic [MATRIX_WIDTH-1:0] buffer_write_enable,

        input   instr_type instr_port,
        input   logic instr_enable,

        output  logic busy,
        output  logic synchronize
    );

    // weight buffer signals
    weight_addr_type weight_addr0;                      // written by: weight_flow_controller, read by: weight_buffer
    logic weight_en0;                                   // written by: weight_flow_controller, read by: weight_buffer
    byte_type [MATRIX_WIDTH-1:0] weight_read_port0;     // written by: weight_buffer, read by: matrix_multiply_unit

    // unified buffer signals
    buffer_addr_type buffer_addr0;                      // written by: matrix_multiplication_flow_controller, read by: unified_buffer
    logic buffer_en0;                                   // written by: matrix_multiplication_flow_controller, read by: unified_buffer
    byte_type [MATRIX_WIDTH-1:0] buffer_read_port0;     // written by: unified_buffer, read by: systolic_data_setup_unit
    buffer_addr_type buffer_addr1;                      // written by: activation_flow_controller, read by: unified_buffer
    logic buffer_write_en1;                             // written by: activation_flow_controller, read by: unified_buffer
    byte_type [MATRIX_WIDTH-1:0] buffer_write_port1;    // written by: activation, read by: unified_buffer

    // systolic data setup unit signals
    byte_type [MATRIX_WIDTH-1:0] sds_systolic_output;   // written by: systolic_data_setup_unit, read by: matrix_multiply_unit

    // matrix multiply unit signals
    logic is_mmu_weight_signed;                         // written by: weight_flow_controller, read by: matrix_mutliply_unit
    logic is_mmu_systolic_signed;                       // written by: matrix_multiplication_flow_controller, read by: matrix_mutliply_unit
    logic mmu_activate_weight;                          // written by: matrix_multiplication_flow_controller, read by: matrix_mutliply_unit
    logic mmu_load_weight;                              // written by: weight_flow_controller, read by: matrix_mutliply_unit
    byte_type mmu_weight_addr;                          // written by: weight_flow_controller, read by: matrix_mutliply_unit
    word_type [MATRIX_WIDTH-1:0] mmu_result;            // written by: matrix_mutliply_unit, read by: register_file

    // register file signals
    accumulator_addr_type reg_write_addr;               // written by: matrix_mutliplication_flow_controller, read by: register_file
    logic reg_write_en;                                 // written by: matrix_mutliplication_flow_controller, read by: register_file
    logic reg_accumulate;                               // written by: matrix_mutliplication_flow_controller, read by: register_file
    accumulator_addr_type reg_read_addr;                // written by: activation_flow_controller, read by: register_file
    word_type [MATRIX_WIDTH-1:0] reg_read_port;         // written by: register_file, read by: activation

    // activation signals
    activation_type activation_function;                // written by: activation_flow_controller, read by: activation
    logic is_activation_signed;                         // written by: activation_flow_controller, read by: activation

    // weight control signals
    weight_instr_type weight_instr;                     // written by: control_coordinator, read by: weight_flow_controller
    logic weight_instr_en;                              // written by: control_coordinator, read by: weight_flow_controller
    logic weight_read_en;                               // written by: none, read by: none
    logic weight_resource_busy;                         // written by: weight_flow_controller, read by: control_coordinator

    // matrix multiplication flow controller signals
    instr_type mmu_instr;                               // written by: control_coordinator, read by: matrix_multiplication_flow_controller
    logic mmu_instr_en;                                 // written by: control_coordinator, read by: matrix_multiplication_flow_controller
    logic buffer_read_en;                               // written by: none, read by: none
    logic mmu_sds_en;                                   // written by: matrix_multiplication_flow_controller, read by: none
    logic mmu_resource_busy;                            // written by: matrix_multiplication_flow_controller, read by: control_coordinator

    // activation flow controller signals
    instr_type activation_instr;                        // written by: control_coordinator, read by: activation_flow_controller
    logic activation_instr_en;                          // written by: control_coordinator, read by: activation_flow_controller
    logic activation_resource_busy;                     // written by: activation_flow_controller, read by: control_coordinator

    // look ahead buffer signals
    logic instr_busy;                                   // written by: control_coordinator, read by: look_ahead_buffer
    instr_type instr_out;                               // written by: look_ahead_buffer, read by: control_coordinator
    logic instr_read;                                   // written by: look_ahead_buffer, read by: control_coordinator

    // control coordinator signals
    logic control_busy;                                 // written by: none, read by: none 
    logic weight_busy;                                  // written by: weight_flow_controller, read by: control_coordinator
    logic matrix_busy;                                  // written by: matrix_multiplication_flow_controller, read by: control_coordinator
    logic activation_busy;                              // written by: activation_flow_controller, read by: control_coordinator

    weight_buffer #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .TILE_WIDTH(WEIGHT_BUFFER_DEPTH)
    ) weight_buffer_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .addr0                          (weight_addr0),                 // input from weight_flow_controller
        .en0                            (weight_en0),                   // input from weight_flow_controller
        .write_en0                      (0),                            // input
        .write_port0                    ('b0),                          // input
        .read_port0                     (weight_read_port0),            // output to matrix_multiply_unit
        .addr1                          (weight_addr),                  // input from tpu_core
        .en1                            (weight_enable),                // input from tpu_core
        .write_en1                      (weight_write_enable),          // input from tpu_core
        .write_port1                    (weight_write_port),            // input from tpu_core
        .read_port1                     ()                              // output
    );

    unified_buffer #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .TILE_WIDTH(UNIFIED_BUFFER_DEPTH)
    ) unified_buffer_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .master_addr                    (buffer_addr),                  // input from tpu_core
        .master_en                      (buffer_enable),                // input from tpu_core
        .master_write_en                (buffer_write_enable),          // input from tpu_core
        .master_write_port              (buffer_write_port),            // input from tpu_core
        .master_read_port               (buffer_read_port),             // output to tpu_core
        .addr0                          (buffer_addr0),                 // input from matrix_multiplication_flow_controller
        .en0                            (buffer_en0),                   // input from matrix_multiplication_flow_controller
        .read_port0                     (buffer_read_port0),            // output to systolic_data_setup_unit
        .addr1                          (buffer_addr1),                 // input from activation_flow_controller
        .en1                            (buffer_write_en1),             // input from activation_flow_controller
        .write_en1                      (buffer_write_en1),             // input from activation_flow_controller
        .write_port1                    (buffer_write_port1)            // input from activation
    );

    systolic_data_setup_unit #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) systolic_data_setup_unit_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .data_in                        (buffer_read_port0),            // input from unified_buffer
        .systolic_data_out              (sds_systolic_output)           // output to matrix_multiply_unit
    );

    matrix_multiply_unit #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) matrix_multiply_unit_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .weight_data                    (weight_read_port0),            // input from weight_buffer
        .weight_signed                  (is_mmu_weight_signed),         // input from weight_flow_controller
        .systolic_data                  (sds_systolic_output),          // input from systolic_data_setup_unit
        .systolic_signed                (is_mmu_systolic_signed),       // input from matrix_multiplication_flow_controller
        .activate_weight                (mmu_activate_weight),          // input from matrix_multiplication_flow_controller
        .load_weight                    (mmu_load_weight),              // input from weight_flow_controller
        .weight_addr                    (mmu_weight_addr),              // input from weight_flow_controller
        .result                         (mmu_result)                    // output to register_file
    );

    register_file #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .REGISTER_DEPTH(512)
    ) register_file_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .write_addr                     (reg_write_addr),               // input from matrix_multiplication_flow_controller
        .data_in                        (mmu_result),                   // input from matrix_multiply_unit
        .write_enable                   (reg_write_en),                 // input from matrix_multiplication_flow_controller
        .accumulate                     (reg_accumulate),               // input from matrix_multiplication_flow_controller
        .read_addr                      (reg_read_addr),                // input from activation_flow_controller
        .data_out                       (reg_read_port)                 // output to activation
    );

    activation #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) activation_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .activation_function            (activation_function),          // input from activation_flow_controller
        .is_signed                      (is_activation_signed),         // input from activation_flow_controller
        .data_in                        (reg_read_port),                // input from register_file
        .data_out                       (buffer_write_port1)            // output to unified_buffer
    );

    weight_flow_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) weight_flow_controller_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .instr                          (weight_instr),                 // input from control_coordinator
        .instr_enable                   (weight_instr_en),              // input from control_coordinator
        .weight_read_enable             (weight_en0),                   // output to weight_buffer
        .weight_buffer_addr             (weight_addr0),                 // output to weight_buffer
        .load_weight                    (mmu_load_weight),              // output to matrix_multiply_unit
        .weight_addr                    (mmu_weight_addr),              // output to matrix_multiply_unit
        .is_weight_signed               (is_mmu_weight_signed),         // output to matrix_multiply_unit
        .busy                           (weight_busy),                  // output to control_coordinator
        .resource_busy                  (weight_resource_busy)          // output to control_coordinator
    );

    matrix_multiplication_flow_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) matrix_multiplication_flow_controller_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .instr                          (mmu_instr),                    // input from control_coordinator
        .instr_enable                   (mmu_instr_en),                 // input from control_coordinator
        .buffer_to_sds_addr             (buffer_addr0),                 // output to unified buffer
        .buffer_read_enable             (buffer_en0),                   // output to unified buffer
        .mmu_sds_enable                 (mmu_sds_en),                   // output to none
        .is_mmu_signed                  (is_mmu_systolic_signed),       // output to matrix_multiply_unit
        .activate_weight                (mmu_activate_weight),          // output to matrix_multiply_unit
        .acc_addr                       (reg_write_addr),               // output to register_file
        .accumulate                     (reg_accumulate),               // output to register_file
        .acc_enable                     (reg_write_en),                 // output to register_file
        .busy                           (matrix_busy),                  // output to control_coordinator
        .resource_busy                  (mmu_resource_busy)             // output to control_coordinator
    );

    activation_flow_controller #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) activation_flow_controller_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .instr                          (activation_instr),             // input from control_coordinator
        .instr_enable                   (activation_instr_en),          // input from control_coordinator
        .acc_to_act_addr                (reg_read_addr),                // output to register_file
        .activation_function            (activation_function),          // output to activation
        .is_signed                      (is_activation_signed),         // output to activation
        .act_to_buf_addr                (buffer_addr1),                 // output to unified buffer
        .buf_write_en                   (buffer_write_en1),             // output to unified buffer
        .busy                           (activation_busy),              // output to control_coordinator
        .resource_busy                  (activation_resource_busy)      // output to control_coordinator
    );

    look_ahead_buffer #(
    ) look_ahead_buffer_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .instr_busy                     (instr_busy),                   // input from control_coordinator
        .instr_in                       (instr_port),                   // input from tpu_core
        .instr_write                    (instr_enable),                 // input from tpu_core
        .instr_out                      (instr_out),                    // output to control_coordinator
        .instr_read                     (instr_read)                    // output to control_coordinator
    );

    control_coordinator #(
    ) control_coordinator_tpu_core (
        .clk                            (clk),                          // input from tpu_core
        .rst                            (rst),                          // input from tpu_core
        .enable                         (enable),                       // input from tpu_core
        .instr                          (instr_out),                    // input from look_ahead_buffer
        .instr_enable                   (instr_read),                   // input from look_ahead_buffer
        .busy                           (instr_busy),                   // output to look_ahead_buffer (and tpu_core, see the assignment below)
        .weight_busy                    (weight_busy),                  // input from weight_flow_controller
        .weight_resource_busy           (weight_resource_busy),         // input from weight_flow_controller
        .weight_instr                   (weight_instr),                 // output to weight_flow_controller
        .weight_instr_enable            (weight_instr_en),              // output to weight_flow_controller
        .matrix_busy                    (matrix_busy),                  // input from matrix_multiplication_flow_controller
        .matrix_resource_busy           (mmu_resource_busy),            // input from matrix_multiplication_flow_controller
        .matrix_instr                   (mmu_instr),                    // output to matrix_multiplication_flow_controller
        .matrix_instr_enable            (mmu_instr_en),                 // output to matrix_multiplication_flow_controller
        .activation_busy                (activation_busy),              // input from activation_flow_controller
        .activation_resource_busy       (activation_resource_busy),     // input from activation_flow_controller
        .activation_instr               (activation_instr),             // output to activation_flow_controller
        .activation_instr_enable        (activation_instr_en),          // output to activation_flow_controller
        .synchronize                    (synchronize)                   // output to tpu_core
    );

    assign busy = instr_busy;           // output to tpu_core
endmodule
