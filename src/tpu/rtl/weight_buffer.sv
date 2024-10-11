// Weight buffer
// Created: 2024-09-28
// Modified: 2024-10-11

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module weight_buffer
    #(
        parameter int MATRIX_WIDTH  = 14,
        parameter int TILE_WIDTH    = 32768
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,

        // port 0
        input   weight_addr_type addr0,
        input   logic en0,
        input   logic write_en0,
        input   byte_type [MATRIX_WIDTH-1:0] write_port0,
        output  byte_type [MATRIX_WIDTH-1:0] read_port0,

        // port 1
        input   weight_addr_type addr1,
        input   logic en1,
        input   logic write_en1,
        input   byte_type [MATRIX_WIDTH-1:0] write_port1,
        output  byte_type [MATRIX_WIDTH-1:0] read_port1
    );

    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] ram [TILE_WIDTH-1:0]
    // synthesis translate_off
        = '{0:  112'h0000000000000000000000000080,
            1:  112'h0000000000000000000000008000,
            2:  112'h0000000000000000000000800000,
            3:  112'h0000000000000000000080000000,
            4:  112'h0000000000000000008000000000,
            5:  112'h0000000000000000800000000000,
            6:  112'h0000000000000080000000000000,
            7:  112'h0000000000008000000000000000,
            8:  112'h0000000000800000000000000000,
            9:  112'h0000000080000000000000000000,
            10: 112'h0000008000000000000000000000,
            11: 112'h0000800000000000000000000000,
            12: 112'h0080000000000000000000000000,
            13: 112'h8000000000000000000000000000,
            default: 112'h0}
    // synthesis translate_on
    ;

    byte_type [MATRIX_WIDTH-1:0] read_port0_reg0_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg1_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg1_ns;

    byte_type [MATRIX_WIDTH-1:0] read_port1_reg0_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port1_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] read_port1_reg1_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port1_reg1_ns;

    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] write_port0_bits;
    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] write_port1_bits;
    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] read_port0_bits;
    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] read_port1_bits;

    // port 0 logic
    always_ff @(posedge clk)
    begin
        if(en0)
        begin
            // synthesis translate_off
            if (addr0 < TILE_WIDTH)
            begin
            // synthesis translate_on
                if(write_en0)
                begin
                    ram[addr0] <= write_port0_bits;
                end
                read_port0_bits <= ram[addr0];
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end

    // port 1 logic
    always_ff @(posedge clk)
    begin
        if(en1)
        begin
            // synthesis translate_off
            if(addr1 < TILE_WIDTH)
            begin
            // synthesis translate_on
                for(int i=0; i<MATRIX_WIDTH; i++)
                begin
                    if(write_en1)
                        ram[addr1][i*BYTE_WIDTH +: BYTE_WIDTH] <= write_port1_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
                end
                read_port1_bits <= ram[addr1];
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end

    // output logic
    always_comb
    begin
        write_port0_bits = write_port0;
        write_port1_bits = write_port1;

        read_port0_reg0_ns = read_port0_bits;
        read_port1_reg0_ns = read_port1_bits;

        read_port0_reg1_ns = read_port0_reg0_cs;
        read_port1_reg1_ns = read_port1_reg0_cs;

        read_port0 = read_port0_reg1_cs;
        read_port1 = read_port1_reg1_cs;
    end

    // next state logic
    always_ff @(posedge clk)
    begin        
        if(rst)
        begin
            read_port0_reg0_cs <= 0;
            read_port0_reg1_cs <= 0;
            read_port1_reg0_cs <= 0;
            read_port1_reg1_cs <= 0;
        end
        else
        begin
            if(enable)
            begin
                read_port0_reg0_cs <= read_port0_reg0_ns;
                read_port0_reg1_cs <= read_port0_reg1_ns;
                read_port1_reg0_cs <= read_port1_reg0_ns;
                read_port1_reg1_cs <= read_port1_reg1_ns;
            end
        end
    end
endmodule
