`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_state_lsu #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 save,
    input  wire                 load,
    output wire                 complete,

    `AXI4_CUSTOM_A_SLAVE_IF     (fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_W_SLAVE_IF     (fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_B_SLAVE_IF     (fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_R_SLAVE_IF     (fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_CUSTOM_A_MASTER_IF    (fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_W_MASTER_IF    (fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_B_MASTER_IF    (fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_R_MASTER_IF    (fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire [31:0]          fifo_a_cnt,
    input  wire [31:0]          fifo_w_cnt,
    input  wire [31:0]          fifo_b_cnt,
    input  wire [31:0]          fifo_r_cnt,

    `AXI4_MASTER_IF_NO_ID       (host_axi, 32, 32)
);

    localparam COUNT_WIDTH = 10;

    // DMA

    wire                    s_read_addr_valid;
    wire                    s_read_addr_ready;
    wire [31:0]             s_read_addr;

    wire                    s_read_count_valid;
    wire                    s_read_count_ready;
    reg  [COUNT_WIDTH-1:0]  s_read_count;

    wire                    m_read_data_valid;
    wire                    m_read_data_ready;
    wire [31:0]             m_read_data;

    wire                    s_write_addr_valid;
    wire                    s_write_addr_ready;
    wire [31:0]             s_write_addr;

    wire                    s_write_count_valid;
    wire                    s_write_count_ready;
    reg  [COUNT_WIDTH-1:0]  s_write_count;

    wire                    s_write_data_valid;
    wire                    s_write_data_ready;
    wire [31:0]             s_write_data;

    wire r_idle, w_idle;

    emulib_simple_dma #(
        .ADDR_WIDTH             (32),
        .DATA_WIDTH             (32),
        .COUNT_WIDTH            (COUNT_WIDTH)
    ) u_dma (

        .clk                    (clk),
        .rst                    (rst),

        .s_read_addr_valid      (s_read_addr_valid),
        .s_read_addr_ready      (s_read_addr_ready),
        .s_read_addr            (s_read_addr),
    
        .s_read_count_valid     (s_read_count_valid),
        .s_read_count_ready     (s_read_count_ready),
        .s_read_count           (s_read_count),

        .m_read_data_valid      (m_read_data_valid),
        .m_read_data_ready      (m_read_data_ready),
        .m_read_data            (m_read_data),

        .s_write_addr_valid     (s_write_addr_valid),
        .s_write_addr_ready     (s_write_addr_ready),
        .s_write_addr           (s_write_addr),

        .s_write_count_valid    (s_write_count_valid),
        .s_write_count_ready    (s_write_count_ready),
        .s_write_count          (s_write_count),

        .s_write_data_valid     (s_write_data_valid),
        .s_write_data_ready     (s_write_data_ready),
        .s_write_data           (s_write_data),

        `AXI4_CONNECT_NO_ID     (m_axi, host_axi),

        .r_idle                 (r_idle),
        .w_idle                 (w_idle)

    );

    wire s_read_addr_fire   = s_read_addr_valid && s_read_addr_ready;
    wire s_read_count_fire  = s_read_count_valid && s_read_count_ready;
    wire s_write_addr_fire  = s_write_addr_valid && s_write_addr_ready;
    wire s_write_count_fire = s_write_count_valid && s_write_count_ready;

    wire save_sel_count;
    wire save_sel_a;
    wire save_sel_w;
    wire save_sel_b;
    wire save_sel_r;

    wire load_sel_count;
    wire load_sel_a;
    wire load_sel_w;
    wire load_sel_b;
    wire load_sel_r;

    // Gate FIFO paths

    `AXI4_CUSTOM_A_WIRE(gated_fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(gated_fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(gated_fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(gated_fifo_save, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    `AXI4_CUSTOM_A_WIRE(gated_fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(gated_fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(gated_fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(gated_fifo_load, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_save_a (
        .s_valid    (fifo_save_avalid),
        .s_ready    (fifo_save_aready),
        .m_valid    (gated_fifo_save_avalid),
        .m_ready    (gated_fifo_save_aready),
        .couple     (save_sel_a)
    );

    assign `AXI4_CUSTOM_A_PAYLOAD(gated_fifo_save) = `AXI4_CUSTOM_A_PAYLOAD(fifo_save);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_save_w (
        .s_valid    (fifo_save_wvalid),
        .s_ready    (fifo_save_wready),
        .m_valid    (gated_fifo_save_wvalid),
        .m_ready    (gated_fifo_save_wready),
        .couple     (save_sel_w)
    );

    assign `AXI4_CUSTOM_W_PAYLOAD(gated_fifo_save) = `AXI4_CUSTOM_W_PAYLOAD(fifo_save);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_save_b (
        .s_valid    (fifo_save_bvalid),
        .s_ready    (fifo_save_bready),
        .m_valid    (gated_fifo_save_bvalid),
        .m_ready    (gated_fifo_save_bready),
        .couple     (save_sel_b)
    );

    assign `AXI4_CUSTOM_B_PAYLOAD(gated_fifo_save) = `AXI4_CUSTOM_B_PAYLOAD(fifo_save);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_save_r (
        .s_valid    (fifo_save_rvalid),
        .s_ready    (fifo_save_rready),
        .m_valid    (gated_fifo_save_rvalid),
        .m_ready    (gated_fifo_save_rready),
        .couple     (save_sel_r)
    );

    assign `AXI4_CUSTOM_R_PAYLOAD(gated_fifo_save) = `AXI4_CUSTOM_R_PAYLOAD(fifo_save);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_load_a (
        .s_valid    (gated_fifo_load_avalid),
        .s_ready    (gated_fifo_load_aready),
        .m_valid    (fifo_load_avalid),
        .m_ready    (fifo_load_aready),
        .couple     (load_sel_a)
    );

    assign `AXI4_CUSTOM_A_PAYLOAD(fifo_load) = `AXI4_CUSTOM_A_PAYLOAD(gated_fifo_load);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_load_w (
        .s_valid    (gated_fifo_load_wvalid),
        .s_ready    (gated_fifo_load_wready),
        .m_valid    (fifo_load_wvalid),
        .m_ready    (fifo_load_wready),
        .couple     (load_sel_w)
    );

    assign `AXI4_CUSTOM_W_PAYLOAD(fifo_load) = `AXI4_CUSTOM_W_PAYLOAD(gated_fifo_load);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_load_b (
        .s_valid    (gated_fifo_load_bvalid),
        .s_ready    (gated_fifo_load_bready),
        .m_valid    (fifo_load_bvalid),
        .m_ready    (fifo_load_bready),
        .couple     (load_sel_b)
    );

    assign `AXI4_CUSTOM_B_PAYLOAD(fifo_load) = `AXI4_CUSTOM_B_PAYLOAD(gated_fifo_load);

    emulib_ready_valid_decouple #(
        .DECOUPLE_M(1),
        .DECOUPLE_S(1)
    ) gate_fifo_load_r (
        .s_valid    (gated_fifo_load_rvalid),
        .s_ready    (gated_fifo_load_rready),
        .m_valid    (fifo_load_rvalid),
        .m_ready    (fifo_load_rready),
        .couple     (load_sel_r)
    );

    assign `AXI4_CUSTOM_R_PAYLOAD(fifo_load) = `AXI4_CUSTOM_R_PAYLOAD(gated_fifo_load);

    // Encoders

    wire                    encoder_a_valid;
    wire                    encoder_a_ready;
    wire [31:0]             encoder_a_data;
    wire                    encoder_a_idle;

    emulib_rammodel_encoder_a #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) encoder_a (
        .clk                    (clk),
        .rst                    (rst),
        `AXI4_CUSTOM_A_CONNECT  (axi, gated_fifo_save),
        .data_valid             (encoder_a_valid),
        .data_ready             (encoder_a_ready),
        .data                   (encoder_a_data),
        .idle                   (encoder_a_idle)
    );

    wire                    encoder_w_valid;
    wire                    encoder_w_ready;
    wire [31:0]             encoder_w_data;
    wire                    encoder_w_idle;

    emulib_rammodel_encoder_w #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) encoder_w (
        .clk                    (clk),
        .rst                    (rst),
        `AXI4_CUSTOM_W_CONNECT  (axi, gated_fifo_save),
        .data_valid             (encoder_w_valid),
        .data_ready             (encoder_w_ready),
        .data                   (encoder_w_data),
        .idle                   (encoder_w_idle)
    );

    wire                    encoder_b_valid;
    wire                    encoder_b_ready;
    wire [31:0]             encoder_b_data;
    wire                    encoder_b_idle;

    emulib_rammodel_encoder_b #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) encoder_b (
        .clk                    (clk),
        .rst                    (rst),
        `AXI4_CUSTOM_B_CONNECT  (axi, gated_fifo_save),
        .data_valid             (encoder_b_valid),
        .data_ready             (encoder_b_ready),
        .data                   (encoder_b_data),
        .idle                   (encoder_b_idle)
    );

    wire                    encoder_r_valid;
    wire                    encoder_r_ready;
    wire [31:0]             encoder_r_data;
    wire                    encoder_r_idle;

    emulib_rammodel_encoder_r #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) encoder_r (
        .clk                    (clk),
        .rst                    (rst),
        `AXI4_CUSTOM_R_CONNECT  (axi, gated_fifo_save),
        .data_valid             (encoder_r_valid),
        .data_ready             (encoder_r_ready),
        .data                   (encoder_r_data),
        .idle                   (encoder_r_idle)
    );

    // Decoders

    wire                    decoder_a_valid;
    wire                    decoder_a_ready;
    wire [31:0]             decoder_a_data;
    wire                    decoder_a_idle;

    emulib_rammodel_decoder_a #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) decoder_a (
        .clk                    (clk),
        .rst                    (rst),
        .data_valid             (decoder_a_valid),
        .data_ready             (decoder_a_ready),
        .data                   (decoder_a_data),
        `AXI4_CUSTOM_A_CONNECT  (axi, gated_fifo_load),
        .idle                   (decoder_a_idle)
    );

    wire                    decoder_w_valid;
    wire                    decoder_w_ready;
    wire [31:0]             decoder_w_data;
    wire                    decoder_w_idle;

    emulib_rammodel_decoder_w #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) decoder_w (
        .clk                    (clk),
        .rst                    (rst),
        .data_valid             (decoder_w_valid),
        .data_ready             (decoder_w_ready),
        .data                   (decoder_w_data),
        `AXI4_CUSTOM_W_CONNECT  (axi, gated_fifo_load),
        .idle                   (decoder_w_idle)
    );

    wire                    decoder_b_valid;
    wire                    decoder_b_ready;
    wire [31:0]             decoder_b_data;
    wire                    decoder_b_idle;

    emulib_rammodel_decoder_b #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) decoder_b (
        .clk                    (clk),
        .rst                    (rst),
        .data_valid             (decoder_b_valid),
        .data_ready             (decoder_b_ready),
        .data                   (decoder_b_data),
        `AXI4_CUSTOM_B_CONNECT  (axi, gated_fifo_load),
        .idle                   (decoder_b_idle)
    );

    wire                    decoder_r_valid;
    wire                    decoder_r_ready;
    wire [31:0]             decoder_r_data;
    wire                    decoder_r_idle;

    emulib_rammodel_decoder_r #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) decoder_r (
        .clk                    (clk),
        .rst                    (rst),
        .data_valid             (decoder_r_valid),
        .data_ready             (decoder_r_ready),
        .data                   (decoder_r_data),
        `AXI4_CUSTOM_R_CONNECT  (axi, gated_fifo_load),
        .idle                   (decoder_r_idle)
    );

    // Multiplexers

    wire        mux_save_count_valid;
    wire        mux_save_count_ready;
    wire [31:0] mux_save_count_data;

    wire        mux_load_count_valid;
    wire        mux_load_count_ready;
    wire [31:0] mux_load_count_data;

    emulib_ready_valid_mux #(
        .NUM_S      (5),
        .NUM_M      (1),
        .DATA_WIDTH (32)
    ) mux_save (
        .s_valid    ({
            mux_save_count_valid,
            encoder_a_valid,
            encoder_w_valid,
            encoder_b_valid,
            encoder_r_valid
        }),
        .s_ready    ({
            mux_save_count_ready,
            encoder_a_ready,
            encoder_w_ready,
            encoder_b_ready,
            encoder_r_ready
        }),
        .s_data     ({
            mux_save_count_data,
            encoder_a_data,
            encoder_w_data,
            encoder_b_data,
            encoder_r_data
        }),
        .s_sel      ({
            save_sel_count,
            save_sel_a,
            save_sel_w,
            save_sel_b,
            save_sel_r
        }),
        .m_valid    (s_write_data_valid),
        .m_ready    (s_write_data_ready),
        .m_data     (s_write_data),
        .m_sel      (1'b1)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (5),
        .DATA_WIDTH (32)
    ) mux_load (
        .s_valid    (m_read_data_valid),
        .s_ready    (m_read_data_ready),
        .s_data     (m_read_data),
        .s_sel      (1'b1),
        .m_valid    ({
            mux_load_count_valid,
            decoder_a_valid,
            decoder_w_valid,
            decoder_b_valid,
            decoder_r_valid
        }),
        .m_ready    ({
            mux_load_count_ready,
            decoder_a_ready,
            decoder_w_ready,
            decoder_b_ready,
            decoder_r_ready
        }),
        .m_data     ({
            mux_load_count_data,
            decoder_a_data,
            decoder_w_data,
            decoder_b_data,
            decoder_r_data
        }),
        .m_sel      ({
            load_sel_count,
            load_sel_a,
            load_sel_w,
            load_sel_b,
            load_sel_r
        })
    );

    // Microcontroller for load/save procedures

    localparam [3:0]
        STATE_IDLE      = 4'd0,
        STATE_FETCH     = 4'd1,
        STATE_DECODE    = 4'd2,
        STATE_DMA_RADDR = 4'd3,
        STATE_DMA_RSIZE = 4'd4,
        STATE_DMA_RWAIT = 4'd5,
        STATE_DMA_WADDR = 4'd6,
        STATE_DMA_WSIZE = 4'd7,
        STATE_DMA_WWAIT = 4'd8;

    localparam [3:0]
        OP_FINISH       = 4'b0000,
        OP_MUL          = 4'b0010,
        OP_ROUTE        = 4'b0100,
        OP_LOAD         = 4'b0101,
        OP_DMA_RADDR    = 4'b1000,
        OP_DMA_RSIZE    = 4'b1001,
        OP_DMA_WADDR    = 4'b1100,
        OP_DMA_WSIZE    = 4'b1101;

    localparam [3:0]
        SIZE_1          = 4'b0000,
        SIZE_CNT        = 4'b0001;

    localparam [3:0]
        ROUTE_A         = 4'b0000,
        ROUTE_W         = 4'b0001,
        ROUTE_B         = 4'b0010,
        ROUTE_R         = 4'b0011,
        ROUTE_CNT       = 4'b1000;
 
    localparam [3:0]
        A_ITEM_SIZE     = ADDR_WIDTH <= 32 ? 4'd2 : 4'd3,
        W_ITEM_SIZE     = DATA_WIDTH <= 32 ? 4'd2 : 4'd3,
        B_ITEM_SIZE     = 4'd1,
        R_ITEM_SIZE     = DATA_WIDTH <= 32 ? 4'd2 : 4'd3;

    wire [7:0] mc_rom ['h2f:0];

    assign

        // Procedure for save

        mc_rom['h00] = {OP_DMA_WADDR,   4'b0000     },

        mc_rom['h01] = {OP_LOAD,        ROUTE_A     },
        mc_rom['h02] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h03] = {OP_DMA_WSIZE,   SIZE_1      },
        mc_rom['h04] = {OP_MUL,         A_ITEM_SIZE },
        mc_rom['h05] = {OP_ROUTE,       ROUTE_A     },
        mc_rom['h06] = {OP_DMA_WSIZE,   SIZE_CNT    },

        mc_rom['h07] = {OP_LOAD,        ROUTE_W     },
        mc_rom['h08] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h09] = {OP_DMA_WSIZE,   SIZE_1      },
        mc_rom['h0a] = {OP_MUL,         W_ITEM_SIZE },
        mc_rom['h0b] = {OP_ROUTE,       ROUTE_W     },
        mc_rom['h0c] = {OP_DMA_WSIZE,   SIZE_CNT    },

        mc_rom['h0d] = {OP_LOAD,        ROUTE_B     },
        mc_rom['h0e] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h0f] = {OP_DMA_WSIZE,   SIZE_1      },
        mc_rom['h10] = {OP_MUL,         B_ITEM_SIZE },
        mc_rom['h11] = {OP_ROUTE,       ROUTE_B     },
        mc_rom['h12] = {OP_DMA_WSIZE,   SIZE_CNT    },

        mc_rom['h13] = {OP_LOAD,        ROUTE_R     },
        mc_rom['h14] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h15] = {OP_DMA_WSIZE,   SIZE_1      },
        mc_rom['h16] = {OP_MUL,         R_ITEM_SIZE },
        mc_rom['h17] = {OP_ROUTE,       ROUTE_R     },
        mc_rom['h18] = {OP_DMA_WSIZE,   SIZE_CNT    },

        mc_rom['h19] = {OP_FINISH,      4'b0000     },

        // Procedure for load

        mc_rom['h1a] = {OP_DMA_RADDR,   4'b0000     },

        mc_rom['h1b] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h1c] = {OP_DMA_RSIZE,   SIZE_1      },
        mc_rom['h1d] = {OP_MUL,         A_ITEM_SIZE },
        mc_rom['h1e] = {OP_ROUTE,       ROUTE_A     },
        mc_rom['h1f] = {OP_DMA_RSIZE,   SIZE_CNT    },

        mc_rom['h20] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h21] = {OP_DMA_RSIZE,   SIZE_1      },
        mc_rom['h22] = {OP_MUL,         W_ITEM_SIZE },
        mc_rom['h23] = {OP_ROUTE,       ROUTE_W     },
        mc_rom['h24] = {OP_DMA_RSIZE,   SIZE_CNT    },

        mc_rom['h25] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h26] = {OP_DMA_RSIZE,   SIZE_1      },
        mc_rom['h27] = {OP_MUL,         B_ITEM_SIZE },
        mc_rom['h28] = {OP_ROUTE,       ROUTE_B     },
        mc_rom['h29] = {OP_DMA_RSIZE,   SIZE_CNT    },

        mc_rom['h2a] = {OP_ROUTE,       ROUTE_CNT   },
        mc_rom['h2b] = {OP_DMA_RSIZE,   SIZE_1      },
        mc_rom['h2c] = {OP_MUL,         R_ITEM_SIZE },
        mc_rom['h2d] = {OP_ROUTE,       ROUTE_R     },
        mc_rom['h2e] = {OP_DMA_RSIZE,   SIZE_CNT    },

        mc_rom['h2f] = {OP_FINISH,      4'b0000     };

    reg [3:0] mc_state, mc_state_next;

    reg [7:0] mc_pc;
    reg [7:0] mc_ins;
    reg [31:0] mc_cnt;

    reg [3:0] mc_route;

    wire dma_w_finish = &{w_idle, encoder_a_idle, encoder_w_idle, encoder_b_idle, encoder_r_idle};
    wire dma_r_finish = &{r_idle, decoder_a_idle, decoder_w_idle, decoder_b_idle, decoder_r_idle};

    always @(posedge clk)
        if (rst)
            mc_state <= STATE_IDLE;
        else
            mc_state <= mc_state_next;

    always @*
        case (mc_state)
        STATE_IDLE:
            if (load || save)
                mc_state_next = STATE_FETCH;
            else
                mc_state_next = STATE_IDLE;
        STATE_FETCH:
            mc_state_next = STATE_DECODE;
        STATE_DECODE:
            case (mc_ins[7:4])
            OP_FINISH:
                mc_state_next = STATE_IDLE;
            OP_MUL:
                mc_state_next = STATE_FETCH;
            OP_ROUTE:
                mc_state_next = STATE_FETCH;
            OP_LOAD:
                mc_state_next = STATE_FETCH;
            OP_DMA_RADDR:
                mc_state_next = STATE_DMA_RADDR;
            OP_DMA_RSIZE:
                mc_state_next = STATE_DMA_RSIZE;
            OP_DMA_WADDR:
                mc_state_next = STATE_DMA_WADDR;
            OP_DMA_WSIZE:
                mc_state_next = STATE_DMA_WSIZE;
            default:
                mc_state_next = STATE_IDLE;
            endcase
        STATE_DMA_RADDR:
            if (s_read_addr_fire)
                mc_state_next = STATE_FETCH;
            else
                mc_state_next = STATE_DMA_RADDR;
        STATE_DMA_RSIZE:
            if (s_read_count_fire)
                mc_state_next = STATE_DMA_RWAIT;
            else
                mc_state_next = STATE_DMA_RSIZE;
        STATE_DMA_RWAIT:
            if (dma_r_finish)
                mc_state_next = STATE_FETCH;
            else
                mc_state_next = STATE_DMA_RWAIT;
        STATE_DMA_WADDR:
            if (s_write_addr_fire)
                mc_state_next = STATE_FETCH;
            else
                mc_state_next = STATE_DMA_WADDR;
        STATE_DMA_WSIZE:
            if (s_write_count_fire)
                mc_state_next = STATE_DMA_WWAIT;
            else
                mc_state_next = STATE_DMA_WSIZE;
        STATE_DMA_WWAIT:
            if (dma_w_finish)
                mc_state_next = STATE_FETCH;
            else
                mc_state_next = STATE_DMA_WWAIT;
        default:
            mc_state_next = STATE_IDLE;
        endcase

    always @(posedge clk)
        if (rst)
            mc_pc <= 0;
        else
            case (mc_state)
            STATE_IDLE:
                mc_pc <= load ? 'h1a : 'h00;
            STATE_FETCH:
                mc_pc <= mc_pc + 1;
            endcase

    always @(posedge clk)
        if (rst)
            mc_ins <= 0;
        else if (mc_state == STATE_FETCH)
            mc_ins <= mc_rom[mc_pc];

    always @(posedge clk)
        if (rst)
            mc_cnt <= 0;
        else if (mc_state == STATE_DECODE)
            case (mc_ins[7:4])
            OP_MUL:
                mc_cnt <= mc_cnt * mc_ins[3:0];
            OP_LOAD:
                case (mc_ins[3:0])
                ROUTE_A:
                    mc_cnt <= fifo_a_cnt;
                ROUTE_W:
                    mc_cnt <= fifo_w_cnt;
                ROUTE_B:
                    mc_cnt <= fifo_b_cnt;
                ROUTE_R:
                    mc_cnt <= fifo_r_cnt;
                endcase
            endcase
        else if (mux_load_count_valid && mux_load_count_ready)
            mc_cnt <= mux_load_count_data;

    always @(posedge clk)
        if (rst)
            mc_route <= 4'd0;
        else if (mc_state == STATE_DECODE && mc_ins[7:4] == OP_ROUTE)
            mc_route <= mc_ins[3:0];

    assign save_sel_count       = mc_state == STATE_DMA_WWAIT && mc_route == ROUTE_CNT;
    assign save_sel_a           = mc_state == STATE_DMA_WWAIT && mc_route == ROUTE_A;
    assign save_sel_w           = mc_state == STATE_DMA_WWAIT && mc_route == ROUTE_W;
    assign save_sel_b           = mc_state == STATE_DMA_WWAIT && mc_route == ROUTE_B;
    assign save_sel_r           = mc_state == STATE_DMA_WWAIT && mc_route == ROUTE_R;

    assign load_sel_count       = mc_state == STATE_DMA_RWAIT && mc_route == ROUTE_CNT;
    assign load_sel_a           = mc_state == STATE_DMA_RWAIT && mc_route == ROUTE_A;
    assign load_sel_w           = mc_state == STATE_DMA_RWAIT && mc_route == ROUTE_W;
    assign load_sel_b           = mc_state == STATE_DMA_RWAIT && mc_route == ROUTE_B;
    assign load_sel_r           = mc_state == STATE_DMA_RWAIT && mc_route == ROUTE_R;

    assign mux_load_count_ready = mc_state == STATE_DMA_RWAIT;

    assign mux_save_count_valid = mc_state == STATE_DMA_WWAIT;
    assign mux_save_count_data  = mc_cnt;

    assign s_read_addr_valid    = mc_state == STATE_DMA_RADDR;
    assign s_read_addr          = 0;

    assign s_read_count_valid   = mc_state == STATE_DMA_RSIZE;

    always @*
        case (mc_ins[3:0])
        SIZE_1:     s_read_count = 1;
        SIZE_CNT:   s_read_count = mc_cnt;
        endcase

    assign s_write_addr_valid   = mc_state == STATE_DMA_WADDR;
    assign s_write_addr         = 0;

    assign s_write_count_valid  = mc_state == STATE_DMA_WSIZE;

    always @*
        case (mc_ins[3:0])
        SIZE_1:     s_write_count = 1;
        SIZE_CNT:   s_write_count = mc_cnt;
        endcase

    assign complete = mc_state == STATE_DECODE && mc_ins[7:4] == OP_FINISH;

`ifdef SIM_LOG_RAMMODEL_STATE_LSU_MC_STATE

    function [255:0] mc_state_name(input [3:0] arg_state);
        begin
            case (arg_state)
                STATE_IDLE:         mc_state_name = "IDLE";
                STATE_FETCH:        mc_state_name = "FETCH";
                STATE_DECODE:       mc_state_name = "DECODE";
                STATE_DMA_RADDR:    mc_state_name = "DMA_RADDR";
                STATE_DMA_RSIZE:    mc_state_name = "DMA_RSIZE";
                STATE_DMA_RWAIT:    mc_state_name = "DMA_RWAIT";
                STATE_DMA_WADDR:    mc_state_name = "DMA_WADDR";
                STATE_DMA_WSIZE:    mc_state_name = "DMA_WSIZE";
                STATE_DMA_WWAIT:    mc_state_name = "DMA_WWAIT";
                default:            mc_state_name = "<UNK>";
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!rst) begin
            if (mc_state != mc_state_next) begin
                $display("[%0d ns] %m: mc_state %0s -> %0s", $time,
                    mc_state_name(mc_state),
                    mc_state_name(mc_state_next));
            end
        end
    end

`endif

`ifdef SIM_LOG_RAMMODEL_STATE_LSU_INS

    function [255:0] mc_op_name(input [3:0] arg_op);
        begin
            case (arg_op)
                OP_FINISH:      mc_op_name = "FINISH";
                OP_MUL:         mc_op_name = "MUL";
                OP_ROUTE:       mc_op_name = "ROUTE";
                OP_LOAD:        mc_op_name = "LOAD";
                OP_DMA_RADDR:   mc_op_name = "DMA_RADDR";
                OP_DMA_RSIZE:   mc_op_name = "DMA_RSIZE";
                OP_DMA_WADDR:   mc_op_name = "DMA_WADDR";
                OP_DMA_WSIZE:   mc_op_name = "DMA_WSIZE";
                default:        mc_op_name = "<UNK>";
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!rst) begin
            if (mc_state == STATE_DECODE) begin
                $display("[%0d ns] %m: mc_ins: %0s, %b", $time,
                    mc_op_name(mc_ins[7:4]),
                    mc_ins[3:0]);
            end
        end
    end

`endif

endmodule

`resetall
