// AXI wrapper module of TPU.sv
// Created:     2025-06-08
// Modified:    2025-06-10

// Copyright (c) 2025 Kagan Dikmen
// See LICENSE for details

`include "./tpu.sv"

module axi_wrapper
    #(
        parameter C_S_AXI_DATA_WIDTH = 32,
        parameter C_S_AXI_ADDR_WIDTH = 20
    )(
        output  logic synchronize,

        input   logic s_axi_aclk,
        input   logic s_axi_aresetn,
        input   logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
        input   logic [2:0] s_axi_awprot,
        input   logic s_axi_awvalid,
        output  logic s_axi_awready,
        input   logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
        input   logic [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
        input   logic s_axi_wvalid,
        output  logic s_axi_wready,
        output  logic [1:0] s_axi_bresp,
        output  logic s_axi_bvalid,
        input   logic s_axi_bready,
        input   logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
        input   logic [2:0] s_axi_arprot,
        input   logic s_axi_arvalid,
        output  logic s_axi_arready,
        output  logic [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
        output  logic [1:0] s_axi_rresp,
        output  logic s_axi_rvalid,
        input   logic s_axi_rready
    );

    localparam MATRIX_WIDTH = 14;
    localparam WEIGHT_BUFFER_DEPTH = 32768;
    localparam UNIFIED_BUFFER_DEPTH = 4096;

    localparam MATRIX_ADDR_WIDTH = $clog2(MATRIX_WIDTH/4);
    localparam WEIGHT_ADDR_BASE = 0;
    localparam WEIGHT_ADDR_END = WEIGHT_BUFFER_DEPTH - 1;
    localparam BUFFER_ADDR_BASE = WEIGHT_BUFFER_DEPTH;
    localparam BUFFER_ADDR_END = WEIGHT_BUFFER_DEPTH + UNIFIED_BUFFER_DEPTH - 1;
    localparam BUFFER_BIT_POSITION = $clog2(BUFFER_ADDR_BASE);
    localparam INSTR_BIT_POSITION = $clog2(UNIFIED_BUFFER_DEPTH);

    localparam MATRIX_ADDR_SIZE = 2**MATRIX_ADDR_WIDTH;
    localparam UPPER_ADDR_WIDTH = $clog2(BUFFER_ADDR_END);
    localparam ADDR_WIDTH = UPPER_ADDR_WIDTH + MATRIX_ADDR_WIDTH;


    logic [1:0] awvalid_arvalid;

    // TPU signals

    logic rst;

    word_type runtime_count;

    word_type lower_instr_word;
    word_type middle_instr_word;
    halfword_type upper_instr_word;
    logic [2:0] instr_write_en;
    logic instr_full;

    byte_type [MATRIX_WIDTH-1:0] weight_write_port;
    weight_addr_type weight_addr;
    logic weight_en;
    logic [MATRIX_WIDTH-1:0] weight_write_en;

    byte_type [MATRIX_WIDTH-1:0] buffer_write_port;
    byte_type [MATRIX_WIDTH-1:0] buffer_read_port;
    buffer_addr_type buffer_addr;
    logic buffer_en;
    logic [MATRIX_WIDTH-1:0] buffer_write_en;


    // Address MUX signals

    weight_addr_type weight_write_addr;
    buffer_addr_type buffer_write_addr;
    buffer_addr_type buffer_read_addr;

    logic buffer_en_on_write, buffer_en_on_read;


    // Input registers for weight buffer

    byte_type [MATRIX_WIDTH-1:0] weight_write_port_reg0_cs = '{default: 'b0};
    byte_type [MATRIX_WIDTH-1:0] weight_write_port_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] weight_write_port_reg1_cs = '{default: 'b0};
    byte_type [MATRIX_WIDTH-1:0] weight_write_port_reg1_ns;
    weight_addr_type weight_addr_reg0_cs = '{default: 'b0};
    weight_addr_type weight_addr_reg0_ns;
    weight_addr_type weight_addr_reg1_cs = '{default: 'b0};
    weight_addr_type weight_addr_reg1_ns;
    logic [MATRIX_WIDTH-1:0] weight_write_en_reg0_cs = '{default: 'b0};
    logic [MATRIX_WIDTH-1:0] weight_write_en_reg0_ns;
    logic [MATRIX_WIDTH-1:0] weight_write_en_reg1_cs = '{default: 'b0};
    logic [MATRIX_WIDTH-1:0] weight_write_en_reg1_ns;
    logic weight_en_on_write_reg0_cs = 1'b0;
    logic weight_en_on_write_reg0_ns;
    logic weight_en_on_write_reg1_cs = 1'b0;
    logic weight_en_on_write_reg1_ns;


    // Input registers for unified buffer

    byte_type [MATRIX_WIDTH-1:0] buffer_write_port_reg0_cs = '{default: 'b0};
    byte_type [MATRIX_WIDTH-1:0] buffer_write_port_reg0_ns;
    byte_type [MATRIX_WIDTH-1:0] buffer_write_port_reg1_cs = '{default: 'b0};
    byte_type [MATRIX_WIDTH-1:0] buffer_write_port_reg1_ns;
    buffer_addr_type buffer_addr_reg0_cs = '{default: 'b0};
    buffer_addr_type buffer_addr_reg0_ns;
    buffer_addr_type buffer_addr_reg1_cs = '{default: 'b0};
    buffer_addr_type buffer_addr_reg1_ns;
    logic [MATRIX_WIDTH-1:0] buffer_write_en_reg0_cs = '{default: 'b0};
    logic [MATRIX_WIDTH-1:0] buffer_write_en_reg0_ns;
    logic [MATRIX_WIDTH-1:0] buffer_write_en_reg1_cs = '{default: 'b0};
    logic [MATRIX_WIDTH-1:0] buffer_write_en_reg1_ns;
    logic buffer_en_on_write_reg0_cs = 1'b0;
    logic buffer_en_on_write_reg0_ns;
    logic buffer_en_on_write_reg1_cs = 1'b0;
    logic buffer_en_on_write_reg1_ns;


    // For read delays

    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay0_cs = '{default: 'b0};
    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay0_ns;
    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay1_cs = '{default: 'b0};
    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay1_ns;
    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay2_cs = '{default: 'b0};
    logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_delay2_ns;

    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay0_cs = '{default: 'b0};
    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay0_ns;
    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay1_cs = '{default: 'b0};
    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay1_ns;
    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay2_cs = '{default: 'b0};
    logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_delay2_ns;


    // Signals from the state machine

    fsm_state_type state_cs = idle;
    fsm_state_type state_ns;

    logic write_accept;

    logic write_addr_en;
    logic [C_S_AXI_ADDR_WIDTH-2-1:0] write_addr_cs = '{default: 'b0};
    logic [C_S_AXI_ADDR_WIDTH-2-1:0] write_addr_ns;
    logic read_addr_en;
    logic [C_S_AXI_ADDR_WIDTH-2-1:0] read_addr_cs = '{default: 'b0};
    logic [C_S_AXI_ADDR_WIDTH-2-1:0] read_addr_ns;
    logic write_data_en;
    logic [C_S_AXI_DATA_WIDTH-1:0] write_data_cs = '{default: 'b0};
    logic [C_S_AXI_DATA_WIDTH-1:0] write_data_ns;
    logic read_data_en;
    logic [C_S_AXI_DATA_WIDTH-1:0] read_data_cs = '{default: 'b0};
    logic [C_S_AXI_DATA_WIDTH-1:0] read_data_ns;

    logic slave_write_en;
    logic slave_read_en;
    logic read_data_on_bus;
    logic [2:0] read_data_delay_cs = '{default: 'b0};
    logic [2:0] read_data_delay_ns;


    //////////////
    //////////////
    //////////////

    assign rst = ~s_axi_aresetn;

    tpu #(.MATRIX_WIDTH(MATRIX_WIDTH), .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH), .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH))
        tpu_i (
            .clk(s_axi_aclk),
            .rst(rst),
            .enable(1'b1),
            .runtime_count(runtime_count),
            .lower_instr_word(lower_instr_word),
            .middle_instr_word(middle_instr_word),
            .upper_instr_word(upper_instr_word),
            .instr_write_enable(instr_write_en),
            .instr_fifo_empty(),
            .instr_fifo_full(instr_full),
            .weight_write_port(weight_write_port),
            .weight_addr(weight_addr),
            .weight_enable(weight_en),
            .weight_write_enable(weight_write_en),
            .buffer_write_port(buffer_write_port),
            .buffer_read_port(buffer_read_port),
            .buffer_addr(buffer_addr),
            .buffer_enable(buffer_en),
            .buffer_write_enable(buffer_write_en),
            .synchronize(synchronize)
        );

    assign upper_read_addr_delay1_ns = upper_read_addr_delay0_cs;
    assign upper_read_addr_delay2_ns = upper_read_addr_delay1_cs;
    assign lower_read_addr_delay1_ns = lower_read_addr_delay0_cs;
    assign lower_read_addr_delay2_ns = lower_read_addr_delay1_cs;

    // Address assignments
    assign weight_addr = weight_write_addr;
    assign buffer_addr = buffer_en_on_write ? buffer_write_addr : buffer_read_addr;

    assign buffer_en = buffer_en_on_write || buffer_en_on_read;

    assign read_data_delay_ns[0] = slave_read_en;
    assign read_data_delay_ns[2:1] = read_data_delay_cs[1:0];
    assign read_data_on_bus = read_data_delay_cs[2];

    // Align on 32 bit
    assign write_addr_ns = s_axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2];
    assign read_addr_ns = s_axi_araddr[C_S_AXI_ADDR_WIDTH-1:2];

    assign write_data_ns = s_axi_wdata;
    assign s_axi_rdata = read_data_cs;

    assign awvalid_arvalid = {s_axi_awvalid, s_axi_arvalid};

    // FSM
    always_comb
    begin
        case(state_cs)
            idle:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b1;
                s_axi_arready   = 1'b1;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                case(awvalid_arvalid)
                    2'b10:
                    begin
                        write_addr_en   = 1'b1;
                        read_addr_en    = 1'b0;
                        state_ns        = write_addr;
                    end
                    2'b01:
                    begin
                        write_addr_en   = 1'b0;
                        read_addr_en    = 1'b1;
                        state_ns        = read_addr;
                    end
                    default:
                    begin
                        write_addr_en   = 1'b0;
                        read_addr_en    = 1'b0;
                        state_ns        = idle;
                    end
                endcase
            end
            write_addr:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b1;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                case(s_axi_wvalid)
                    1'b0:
                    begin
                        write_data_en   = 1'b0;
                        state_ns        = write_addr;
                    end
                    1'b1:
                    begin
                        write_data_en   = 1'b1;
                        state_ns        = write_data;
                    end
                    default:
                    begin
                        write_data_en   = 1'b0;
                        state_ns        = write_addr;
                    end
                endcase
            end
            write_data:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b1;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                case(write_accept)
                    1'b0:
                    begin
                        state_ns        = write_data;
                    end
                    1'b1:
                    begin
                        state_ns        = write_resp;
                    end
                    default:
                    begin
                        state_ns        = write_data;
                    end
                endcase
            end
            write_resp:
            begin
                s_axi_bresp     = 2'b00;
                s_axi_bvalid    = 1'b1;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                case(s_axi_bready)
                    1'b0:
                    begin
                        state_ns        = write_resp;
                    end
                    1'b1:
                    begin
                        state_ns        = idle;
                    end
                    default:
                    begin
                        state_ns        = write_resp;
                    end
                endcase
            end
            read_addr:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                case(s_axi_rready)
                    1'b0:
                    begin
                        slave_read_en   = 1'b0;
                        state_ns        = read_addr;
                    end
                    1'b1:
                    begin
                        slave_read_en   = 1'b1;
                        state_ns        = read_data;
                    end
                    default:
                    begin
                        slave_read_en   = 1'b0;
                        state_ns        = read_addr;
                    end
                endcase
            end
            read_data:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                case(read_data_on_bus)
                    1'b0:
                    begin
                        read_data_en    = 1'b0;
                        state_ns        = read_data;
                    end
                    1'b1:
                    begin
                        read_data_en    = 1'b1;
                        state_ns        = read_resp;
                    end
                    default:
                    begin
                        read_data_en    = 1'b0;
                        state_ns        = read_data;
                    end
                endcase
            end
            read_resp:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b1;
                s_axi_rresp     = 2'b00;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                state_ns        = idle;
            end
            default:
            begin
                s_axi_bresp     = 2'b10;
                s_axi_bvalid    = 1'b0;
                s_axi_rvalid    = 1'b0;
                s_axi_rresp     = 2'b10;
                s_axi_awready   = 1'b0;
                s_axi_arready   = 1'b0;
                s_axi_wready    = 1'b0;
                slave_write_en  = 1'b0;
                read_data_en    = 1'b0;
                slave_read_en   = 1'b0;
                write_data_en   = 1'b0;
                write_addr_en   = 1'b0;
                read_addr_en    = 1'b0;
                state_ns        = idle;
            end
        endcase
    end

    assign weight_write_port_reg1_ns = weight_write_port_reg0_cs;
    assign weight_write_port = weight_write_port_reg1_cs;

    assign weight_addr_reg1_ns = weight_addr_reg0_cs;
    assign weight_write_addr = weight_addr_reg1_cs;

    assign weight_write_en_reg1_ns = weight_write_en_reg0_cs;
    assign weight_write_en = weight_write_en_reg1_cs;
     
    assign weight_en_on_write_reg1_ns = weight_en_on_write_reg0_cs;
    assign weight_en = weight_en_on_write_reg1_cs;
    /////
    assign buffer_write_port_reg1_ns = buffer_write_port_reg0_cs;
    assign buffer_write_port = buffer_write_port_reg1_cs;

    assign buffer_addr_reg1_ns = buffer_addr_reg0_cs;
    assign buffer_write_addr = buffer_addr_reg1_cs;

    assign buffer_write_en_reg1_ns = buffer_write_en_reg0_cs;
    assign buffer_write_en = buffer_write_en_reg1_cs;
     
    assign buffer_en_on_write_reg1_ns = buffer_en_on_write_reg0_cs;
    assign buffer_en_on_write = buffer_en_on_write_reg1_cs;

    /////

    always_comb
    begin

        logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_write_addr_v;
        logic [MATRIX_ADDR_WIDTH-1:0] lower_write_addr_v;

        upper_write_addr_v = write_addr_cs[ADDR_WIDTH-1:MATRIX_ADDR_WIDTH];
        lower_write_addr_v = write_addr_cs[MATRIX_ADDR_WIDTH-1:0];

        lower_instr_word = write_data_cs;
        middle_instr_word = write_data_cs;
        upper_instr_word = write_data_cs[2*BYTE_WIDTH-1:0];
     
        for(int i=0; i<MATRIX_WIDTH; i=i+1)
        begin
            weight_write_port_reg0_ns[i] = write_data_cs[((i%4)+1)*BYTE_WIDTH-1 -: BYTE_WIDTH];
            buffer_write_port_reg0_ns[i] = write_data_cs[((i%4)+1)*BYTE_WIDTH-1 -: BYTE_WIDTH];
        end

        weight_addr_reg0_ns[BUFFER_BIT_POSITION-1:0] = upper_write_addr_v[BUFFER_BIT_POSITION-1:0];
        weight_addr_reg0_ns[WEIGHT_ADDR_WIDTH-1:BUFFER_BIT_POSITION] = '{default: 1'b0};

        buffer_addr_reg0_ns[INSTR_BIT_POSITION-1:0] = upper_write_addr_v[INSTR_BIT_POSITION-1:0];
        buffer_addr_reg0_ns[BUFFER_ADDR_WIDTH-1:INSTR_BIT_POSITION] = '{default: 1'b0};

        if(slave_write_en)
        begin
            if( ! upper_write_addr_v[BUFFER_BIT_POSITION])
            begin
                instr_write_en = 3'b000;
                weight_en_on_write_reg0_ns = 1'b1;
                for(int i=0; i<MATRIX_WIDTH; i=i+1)
                begin
                    if((i >> 2) == int'(lower_write_addr_v))
                    begin
                        if(s_axi_wstrb[i%4])
                            weight_write_en_reg0_ns[i] = 1'b1;
                        else
                            weight_write_en_reg0_ns[i] = 1'b0;
                    end
                    else
                        weight_write_en_reg0_ns[i] = 1'b0;
                end
                buffer_en_on_write_reg0_ns = 1'b0;
                buffer_write_en_reg0_ns = '{default: 1'b0};
                write_accept = 1'b1;
            end
            else if( ! upper_write_addr_v[INSTR_BIT_POSITION])
            begin
                instr_write_en = 3'b000;
                weight_en_on_write_reg0_ns = 1'b0;
                weight_write_en_reg0_ns = '{default: 1'b0};
                buffer_en_on_write_reg0_ns = 1'b1;
                for(int i=0; i<MATRIX_WIDTH; i=i+1)
                begin
                    if((i >> 2) == int'(lower_write_addr_v))
                    begin
                        if(s_axi_wstrb[i%4])
                            buffer_write_en_reg0_ns[i] = 1'b1;
                        else
                            buffer_write_en_reg0_ns[i] = 1'b0;
                    end
                    else
                        buffer_write_en_reg0_ns[i] = 1'b0;
                end
                write_accept = 1'b1;
            end
            else
            begin
                case(lower_write_addr_v)
                    'd1:
                    begin
                        if(instr_full)
                        begin
                            instr_write_en = 3'b000;
                            write_accept = 1'b0;
                        end
                        else
                        begin
                            instr_write_en = 3'b100;
                            write_accept = 1'b1;
                        end
                    end
                    'd2:
                    begin
                        if(instr_full)
                        begin
                            instr_write_en = 3'b000;
                            write_accept = 1'b0;
                        end
                        else
                        begin
                            instr_write_en = 3'b010;
                            write_accept = 1'b1;
                        end
                    end
                    'd3:
                    begin
                        if(instr_full)
                        begin
                            instr_write_en = 3'b000;
                            write_accept = 1'b0;
                        end
                        else
                        begin
                            instr_write_en = 3'b001;
                            write_accept = 1'b1;
                        end
                    end
                    default:
                    begin
                        instr_write_en = 3'b000;
                        write_accept = 1'b1;
                    end
                endcase
                weight_en_on_write_reg0_ns = 1'b0;
                weight_write_en_reg0_ns = '{default: 1'b0};
                buffer_en_on_write_reg0_ns = 1'b0;
                buffer_write_en_reg0_ns = '{default: 1'b0};
            end
        end
        else
        begin
            instr_write_en = 3'b000;
            weight_en_on_write_reg0_ns = 1'b0;
            weight_write_en_reg0_ns = '{default: 1'b0};
            buffer_en_on_write_reg0_ns = 1'b0;
            buffer_write_en_reg0_ns = '{default: 1'b0};
            write_accept = 1'b1;
        end
    end

    always_comb
    begin
        
        logic [ADDR_WIDTH-MATRIX_ADDR_WIDTH-1:0] upper_read_addr_v;
        logic [MATRIX_ADDR_WIDTH-1:0] lower_read_addr_v;

        upper_read_addr_v = read_addr_cs[ADDR_WIDTH-1:MATRIX_ADDR_WIDTH];
        lower_read_addr_v = read_addr_cs[MATRIX_ADDR_WIDTH-1:0];

        upper_read_addr_delay0_ns = upper_read_addr_v;
        lower_read_addr_delay0_ns = lower_read_addr_v;

        buffer_read_addr[INSTR_BIT_POSITION-1:0] = upper_read_addr_v[INSTR_BIT_POSITION-1:0];
        buffer_read_addr[BUFFER_ADDR_WIDTH-1:INSTR_BIT_POSITION] = '{default: 1'b0};

        if(slave_read_en)
        begin
            if(upper_read_addr_v[BUFFER_BIT_POSITION] && !upper_read_addr_v[INSTR_BIT_POSITION])
                buffer_en_on_read = 1'b1;
            else
                buffer_en_on_read = 1'b0;
        end
        else
            buffer_en_on_read = 1'b0;

        //  Read
        if( ! upper_read_addr_delay2_cs[BUFFER_BIT_POSITION] )
        begin
            read_data_ns = '{default: 1'b0};
        end
        else if ( ! upper_read_addr_delay2_cs[INSTR_BIT_POSITION] )
        begin
            for(int i=0; i<4; i=i+1)
            begin
                if(lower_read_addr_delay2_cs*4+i > MATRIX_WIDTH-1)
                    read_data_ns[(i+1)*BYTE_WIDTH-1 -: BYTE_WIDTH] = '{default: 1'b0};
                else
                    read_data_ns[(i+1)*BYTE_WIDTH-1 -: BYTE_WIDTH] = buffer_read_port[lower_read_addr_delay2_cs*4+i];
            end
        end
        else
        begin
            case(lower_read_addr_delay2_cs)
            'd0:
                read_data_ns = runtime_count;
            default:
                read_data_ns = '{default: 1'b0};
            endcase
        end
    end

    always_ff @(posedge s_axi_aclk)
    begin
        if(rst)
        begin
            state_cs                    <= idle;
            read_data_delay_cs          <= '{default: 1'b0};
            write_addr_cs               <= '{default: 1'b0};
            read_addr_cs                <= '{default: 1'b0};
            write_data_cs               <= '{default: 1'b0};
            read_data_cs                <= '{default: 1'b0};
            upper_read_addr_delay0_cs   <= '{default: 1'b0}; 
            upper_read_addr_delay1_cs   <= '{default: 1'b0};
            upper_read_addr_delay2_cs   <= '{default: 1'b0};
            lower_read_addr_delay0_cs   <= '{default: 1'b0};
            lower_read_addr_delay1_cs   <= '{default: 1'b0};
            lower_read_addr_delay2_cs   <= '{default: 1'b0};
            weight_write_port_reg0_cs   <= '{default: '{default: 1'b0}};
            weight_write_port_reg1_cs   <= '{default: '{default: 1'b0}};
            weight_addr_reg0_cs         <= '{default: 1'b0};
            weight_addr_reg1_cs         <= '{default: 1'b0};
            weight_write_en_reg0_cs     <= '{default: 1'b0};
            weight_write_en_reg1_cs     <= '{default: 1'b0};
            weight_en_on_write_reg0_cs  <= 1'b0;
            weight_en_on_write_reg1_cs  <= 1'b0;
            buffer_write_port_reg0_cs   <= '{default: '{default: 1'b0}};
            buffer_write_port_reg1_cs   <= '{default: '{default: 1'b0}};
            buffer_addr_reg0_cs         <= '{default: 1'b0};
            buffer_addr_reg1_cs         <= '{default: 1'b0};
            buffer_write_en_reg0_cs     <= '{default: 1'b0};
            buffer_write_en_reg1_cs     <= '{default: 1'b0};
            buffer_en_on_write_reg0_cs  <= 1'b0;
            buffer_en_on_write_reg1_cs  <= 1'b0;
        end
        else
        begin

            state_cs                    <= state_ns;
            read_data_delay_cs          <= read_data_delay_ns;

            if(write_addr_en)
                write_addr_cs           <= write_addr_ns;
            
            if(read_addr_en)
                read_addr_cs            <= read_addr_ns;

            if(write_data_en)
                write_data_cs           <= write_data_ns;

            if(read_data_en)
                read_data_cs            <= read_data_ns;

            upper_read_addr_delay0_cs   <= upper_read_addr_delay0_ns; 
            upper_read_addr_delay1_cs   <= upper_read_addr_delay1_ns;
            upper_read_addr_delay2_cs   <= upper_read_addr_delay2_ns;
            lower_read_addr_delay0_cs   <= lower_read_addr_delay0_ns;
            lower_read_addr_delay1_cs   <= lower_read_addr_delay1_ns;
            lower_read_addr_delay2_cs   <= lower_read_addr_delay2_ns;
            weight_write_port_reg0_cs   <= weight_write_port_reg0_ns;
            weight_write_port_reg1_cs   <= weight_write_port_reg1_ns;
            weight_addr_reg0_cs         <= weight_addr_reg0_ns;
            weight_addr_reg1_cs         <= weight_addr_reg1_ns;
            weight_write_en_reg0_cs     <= weight_write_en_reg0_ns;
            weight_write_en_reg1_cs     <= weight_write_en_reg1_ns;
            weight_en_on_write_reg0_cs  <= weight_en_on_write_reg0_ns;
            weight_en_on_write_reg1_cs  <= weight_en_on_write_reg1_ns;
            buffer_write_port_reg0_cs   <= buffer_write_port_reg0_ns;
            buffer_write_port_reg1_cs   <= buffer_write_port_reg1_ns;
            buffer_addr_reg0_cs         <= buffer_addr_reg0_ns;
            buffer_addr_reg1_cs         <= buffer_addr_reg1_ns;
            buffer_write_en_reg0_cs     <= buffer_write_en_reg0_ns;
            buffer_write_en_reg1_cs     <= buffer_write_en_reg1_ns;
            buffer_en_on_write_reg0_cs  <= buffer_en_on_write_reg0_ns;
            buffer_en_on_write_reg1_cs  <= buffer_en_on_write_reg1_ns;
        end
    end
    


endmodule