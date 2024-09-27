// FIFO unit
// Created: 2024-09-27
// Modified: 2024-09-27

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

module fifo
    #(
        parameter int FIFO_DEPTH = 32,
        parameter int FIFO_WIDTH = 8
    )(
        input logic clk,
        input logic rst,
        input logic [FIFO_WIDTH-1:0] data_in,
        input logic write_en,

        output logic [FIFO_WIDTH-1:0] data_out,
        input logic next_en,

        output logic empty,
        output logic full
    );

    localparam address_width = $clog2(FIFO_DEPTH);

    logic [address_width-1:0] read_ptr_cs, read_ptr_ns, write_ptr_cs, write_ptr_ns;
    logic empty_cs, empty_ns, full_cs, full_ns;
    logic looped_cs, looped_ns;

    dist_ram #(
        .DATA_WIDTH(FIFO_WIDTH),
        .DATA_DEPTH(FIFO_DEPTH),
        .ADDRESS_WIDTH(address_width)
    ) ram_i (
        .clk(clk),
        .in_addr(write_ptr_cs),
        .data_in(data_in),
        .write_en(write_en),
        .out_addr(read_ptr_cs),
        .data_out(data_out)
    );

    // logic for full/empty flags
    always_comb
    begin
        empty = empty_cs;
        full = full_cs;
    end

    // state transition logic
    always_ff @(posedge clk)
    begin
        if(rst)
        begin
            write_ptr_cs    <= 'b0;
            read_ptr_cs     <= 'b0;
            looped_cs       <= 1'b0;
            empty_cs        <= 1'b1;
            full_cs         <= 1'b0;
        end
        else
        begin
            write_ptr_cs    <= write_ptr_ns;
            read_ptr_cs     <= read_ptr_ns;
            looped_cs       <= looped_ns;
            empty_cs        <= empty_ns;
            full_cs         <= full_ns;
        end
    end

    // next state logic
    always_comb
    begin

        read_ptr_ns     = read_ptr_cs;
        write_ptr_ns    = write_ptr_cs;
        empty_ns        = empty_cs;
        full_ns         = full_cs;
        looped_ns       = looped_cs;

        if(next_en & (write_ptr_cs != read_ptr_cs | looped_cs))
        begin
            if(read_ptr_cs == FIFO_DEPTH-1)
            begin
                read_ptr_ns = 'b0;
                looped_ns = 1'b0;
            end
            else
            begin
                read_ptr_ns = read_ptr_cs + 1;
            end
        end

        if(write_en & (write_ptr_cs != read_ptr_cs | !looped_cs))
        begin
            if(write_ptr_cs == FIFO_DEPTH-1)
            begin
                write_ptr_ns = 'b0;
                looped_ns = 1'b1;
            end
            else
            begin
                write_ptr_ns = write_ptr_cs + 1;
            end
        end

        if(write_ptr_cs == read_ptr_cs)
        begin
            if(looped_cs)
            begin
                empty_ns = 1'b0;
                full_ns = 1'b1;
            end
            else
            begin
                empty_ns = 1'b1;
                full_ns = 1'b0;
            end
        end
        else
        begin
            empty_ns    = 1'b0;
            full_ns     = 1'b0;
        end
    end

endmodule
