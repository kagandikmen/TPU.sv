// Testbench for AXI wrapper module
// Created:     2025-06-09
// Modified:    2025-06-10

// Copyright (c) 2025 Kagan Dikmen
// See LICENSE for details

`timescale 1ns/1ps

`include "../lib/tpu_pkg.sv"
`include "../rtl/axi_wrapper.sv"

import tpu_pkg::*;

module tb_axi_wrapper
    #()();

    localparam C_S_AXI_DATA_WIDTH = 32;
    localparam C_S_AXI_ADDR_WIDTH = 20;

    logic clk;
    logic nreset;
    logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
    logic [2:0] s_axi_awprot;
    logic s_axi_awvalid;
    logic s_axi_awready;
    logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata;
    logic [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb;
    logic s_axi_wvalid;
    logic s_axi_wready;
    logic [1:0] s_axi_bresp;
    logic s_axi_bvalid;
    logic s_axi_bready;
    logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr;
    logic [2:0] s_axi_arprot;
    logic s_axi_arvalid;
    logic s_axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata;
    logic [1:0] s_axi_rresp;
    logic s_axi_rvalid;
    logic s_axi_rready;

    instr_type instr;

    axi_wrapper #(.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH), .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH))
        dut 
        (
            .s_axi_aclk(clk),
            .s_axi_aresetn(nreset),
            .s_axi_awaddr(s_axi_awaddr),
            .s_axi_awprot(s_axi_awprot),
            .s_axi_awvalid(s_axi_awvalid),
            .s_axi_awready(s_axi_awready),
            .s_axi_wdata(s_axi_wdata),
            .s_axi_wstrb(s_axi_wstrb),
            .s_axi_wvalid(s_axi_wvalid),
            .s_axi_wready(s_axi_wready),
            .s_axi_bresp(s_axi_bresp),
            .s_axi_bvalid(s_axi_bvalid),
            .s_axi_bready(s_axi_bready),
            .s_axi_araddr(s_axi_araddr),
            .s_axi_arprot(s_axi_arprot),
            .s_axi_arvalid(s_axi_arvalid),
            .s_axi_arready(s_axi_arready),
            .s_axi_rdata(s_axi_rdata),
            .s_axi_rresp(s_axi_rresp),
            .s_axi_rvalid(s_axi_rvalid),
            .s_axi_rready(s_axi_rready)
        );
    
    task automatic axi_write
        (
            input logic [C_S_AXI_ADDR_WIDTH-1:0] addr,
            input logic [C_S_AXI_DATA_WIDTH-1:0] data,
            input logic [3:0] strobe
        );
    begin
        s_axi_awaddr <= addr;
        s_axi_awvalid <= 1'b1;

        @(posedge clk);

        s_axi_awvalid <= 1'b0;

        @(posedge clk);

        s_axi_wdata <= data;
        s_axi_wstrb <= strobe;
        s_axi_wvalid <= 1'b1;

        @(posedge clk);

        s_axi_wvalid <= 1'b0;

        @(posedge clk);

        s_axi_bready <= 1'b1;

        @(posedge clk);

        s_axi_bready <= 1'b0;

        @(posedge clk);
    end
    endtask

    task automatic axi_read
        (
            input logic [C_S_AXI_ADDR_WIDTH-1:0] addr
        );
    begin
        s_axi_araddr <= addr;
        s_axi_arvalid <= 1'b1;

        @(posedge clk);

        s_axi_arvalid <= 1'b0;

        @(posedge clk);

        s_axi_rready <= 1'b1;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        s_axi_rready <= 1'b0;

        @(posedge clk);
    end
    endtask

    // clock generation
    always #5   clk = ~clk;

    // stimuli
    initial
    begin
        //initialize signals
        clk <= 1'b0;
        s_axi_araddr <= '{default: 1'b0};
        s_axi_awprot <= '{default: 1'b0};
        s_axi_awvalid <= 1'b0;
        s_axi_wdata <= '{default: 1'b0};
        s_axi_wstrb <= '{default: 1'b0};
        s_axi_wvalid <= 1'b0;
        s_axi_bready <= 1'b0;
        s_axi_araddr <= '{default: 1'b0};
        s_axi_arprot <= '{default: 1'b0};
        s_axi_arvalid <= 1'b0;
        s_axi_rready <= 1'b0;

        nreset <= 1'b0;
        @(posedge clk);
        nreset <= 1'b1;
        @(posedge clk);

        axi_write('h00000, 'hAFFEDEAD, 'b1111);
        axi_write('h00004, 'hDEADAFFE, 'b1111);
        axi_write('h00008, 'h12345678, 'b1111);
        axi_write('h0000C, 'hFEEDC0FE, 'b1111);
        axi_write('h00958, 'h12345678, 'b1111);
        axi_write('h7FFFC, 'hFEEDC0FE, 'b1111);

        axi_write('h80000, 'hAFFEDEAD, 'b1111);
        axi_write('h80004, 'hDEADAFFE, 'b1111);
        axi_write('h80008, 'h12345678, 'b1111);
        axi_write('h8000C, 'hFEEDC0FE, 'b1111);
        axi_write('h80958, 'h12345678, 'b1111);
        axi_write('h8FFFC, 'hFEEDC0FE, 'b1111);

        axi_write('h90000, 'hAFFEDEAD, 'b1111);

        instr.opcode = 8'b0000_1000;
        instr.length = LENGTH_WIDTH;
        instr.acc_addr = 'b0;
        instr.buffer_addr = 'b0;

        axi_write('h90004, instr[1*4*BYTE_WIDTH-1 : 0*4*BYTE_WIDTH], 'b1111);
        axi_write('h90008, instr[2*4*BYTE_WIDTH-1 : 1*4*BYTE_WIDTH], 'b1111);
        axi_write('h9000C, {'h0000, instr[2*4*BYTE_WIDTH+2*BYTE_WIDTH-1 : 2*4*BYTE_WIDTH]}, 'b1111);

        axi_read(20'h00000);
        axi_read(20'h00004);
        axi_read(20'h00008);
        axi_read(20'h0000C);
        axi_read(20'h00958);
        axi_read(20'h7FFFC);

        axi_read(20'h80000);
        axi_read(20'h80004);
        axi_read(20'h80008);
        axi_read(20'h8000C);
        axi_read(20'h80958);
        axi_read(20'h8FFFC);

        axi_read(20'h90000);
        axi_read(20'h90004);
        axi_read(20'h90008);
        axi_read(20'h9000C);
    end
    
endmodule