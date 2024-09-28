// Unified buffer
// Created: 2024-09-28
// Modified: 2024-09-28

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

`include "../lib/tpu_pkg.sv"

import tpu_pkg::*;

module unified_buffer
    #(
        parameter int MATRIX_WIDTH  = 14,
        parameter int TILE_WIDTH    = 4096
    )(
        input   logic clk,
        input   logic rst,
        input   logic enable,
        
        input   buffer_addr_type master_addr,
        input   logic master_en,
        input   logic [MATRIX_WIDTH-1:0] master_write_en,
        input   byte_type [MATRIX_WIDTH-1:0] master_write_port,
        output  byte_type [MATRIX_WIDTH-1:0] master_read_port,

        // port 0
        input   buffer_addr_type addr0,
        input   logic en0,
        output  byte_type [MATRIX_WIDTH-1:0] read_port0,

        // port 1
        input   buffer_addr_type addr1,
        input   logic en1,
        input   logic write_en1,
        input   byte_type [MATRIX_WIDTH-1:0] write_port1
    );

    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] ram [TILE_WIDTH-1:0]
    // synthesis translate_off
        = '{0:112'h72737475767778797A7B7C7D7E7F,
            1:112'h6465666768696A6B6C6D6E6F7071,
            2:112'h565758595A5B5C5D5E5F60616263,
            3:112'h48494A4B4C4D4E4F505152535455,
            4:112'h3A3B3C3D3E3F4041424344454647,
            5:112'h2C2D2E2F30313233343536373839,
            6:112'h1E1F202122232425262728292A2B,
            7:112'h101112131415161718191A1B1C1D,
            8:112'h02030405060708090A0B0C0D0E0F,
            9:112'hF4F5F6F7F8F9FAFBFCFDFEFF0001,
            10:112'hE6E7E8E9EAEBECEDEEEFF0F1F2F3,
            11:112'hD8D9DADBDCDDDEDFE0E1E2E3E4E5,
            12:112'hCACBCCCDCECFD0D1D2D3D4D5D6D7,
            13:112'hBCBDBEBFC0C1C2C3C4C5C6C7C8C9,
            default: 112'h0}
    // synthesis translate_on
    ;

    byte_type [MATRIX_WIDTH-1:0] read_port0_reg0_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg1_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] read_port0_reg1_ns;

    byte_type [MATRIX_WIDTH-1:0] master_read_port_reg0_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] master_read_port_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] master_read_port_reg1_cs = '{default: 'h0};
    byte_type [MATRIX_WIDTH-1:0] master_read_port_reg1_ns;

    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] write_port1_bits;
    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] read_port0_bits;

    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] master_write_port_bits;
    logic [MATRIX_WIDTH*BYTE_WIDTH-1:0] master_read_port_bits;

    buffer_addr_type addr0_override;
    buffer_addr_type addr1_override;

    logic en0_override;
    logic en1_override;

    // port 0 logic
    always_ff @(posedge clk)
    begin
        if(en0_override)
        begin
            // synthesis translate_off
            if (addr0_override < TILE_WIDTH)
            begin
            // synthesis translate_on
                for(int i=0; i<MATRIX_WIDTH; i++)
                begin
                    if(master_write_en[i])
                    begin
                        ram[addr0_override][i*BYTE_WIDTH +: BYTE_WIDTH] <= master_write_port_bits[i*BYTE_WIDTH +: BYTE_WIDTH];
                    end
                end
                read_port0_bits <= ram[addr0_override];
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end

    // port 1 logic
    always_ff @(posedge clk)
    begin
        if(en1_override)
        begin
            // synthesis translate_off
            if(addr1_override < TILE_WIDTH)
            begin
            // synthesis translate_on
                if(write_en1)
                begin
                    ram[addr1_override] <= write_port1_bits;
                end
                master_read_port_bits <= ram[addr1_override];
            // synthesis translate_off
            end
            // synthesis translate_on
        end
    end

    // override logic
    always_comb
    begin
        if(master_en)
        begin
            en0_override = master_en;
            en1_override = master_en;
            addr0_override = master_addr;
            addr1_override = master_addr;
        end
        else
        begin
            en0_override = en0;
            en1_override = en1;
            addr0_override = addr0;
            addr1_override = addr1;
        end
    end

    // output logic
    always_comb
    begin
        write_port1_bits = write_port1;
        master_write_port_bits = master_write_port;

        read_port0_reg0_ns = read_port0_bits;
        read_port0_reg1_ns = read_port0_reg0_cs;
        read_port0 = read_port0_reg1_cs;

        master_read_port_reg0_ns = master_read_port_bits;
        master_read_port_reg1_ns = master_read_port_reg0_cs;
        master_read_port = master_read_port_reg1_cs;
    end

    // next state logic
    always_ff @(posedge clk)
    begin        
        if(rst)
        begin
            read_port0_reg0_cs <= 0;
            read_port0_reg1_cs <= 0;
            master_read_port_reg0_cs <= 0;
            master_read_port_reg1_cs <= 0;
        end
        else
        begin
            if(enable)
            begin
                read_port0_reg0_cs <= read_port0_reg0_ns;
                read_port0_reg1_cs <= read_port0_reg1_ns;
                master_read_port_reg0_cs <= master_read_port_reg0_ns;
                master_read_port_reg1_cs <= master_read_port_reg1_ns;
            end
        end
    end
endmodule
