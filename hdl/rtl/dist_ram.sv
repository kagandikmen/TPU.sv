// Distributed RAM
// Created: 2024-09-27
// Modified: 2024-09-27

// Copyright (c) 2024 Kagan Dikmen
// See LICENSE for details

module dist_ram
    #(
        parameter int DATA_WIDTH = 8,
        parameter int DATA_DEPTH = 32,
        parameter int ADDRESS_WIDTH = 5
    )(
        input logic clk,
        input logic [ADDRESS_WIDTH-1:0] in_addr,
        input logic [DATA_WIDTH-1:0] data_in,
        input logic write_en,
        input logic [ADDRESS_WIDTH-1:0] out_addr,

        output logic [DATA_WIDTH-1:0] data_out
    );

    logic [DATA_WIDTH-1:0] ram [DATA_DEPTH-1:0];

    always_ff @(posedge clk)
    begin
        if (write_en)
        begin
            ram [in_addr] <= data_in;
        end
    end

    always_comb
    begin
        data_out = ram [out_addr];
    end
endmodule
