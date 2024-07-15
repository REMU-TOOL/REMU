`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axi4_trace_recorder #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
) (
    input clk,
    input rst,
    `AXI4_SLAVE_IF                  (s_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF                 (m_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
);
    /*
     * Cycle == 64 BIT
     * Channel Num == 3 BIT
     * Event Sel == 5 BIT
     * AR AW R W B -- 8 BIT aligned
     */
    // formanted payload length + timestamp width
    localparam A_PAYLOAD_FORMANTTED_WIDTH = ((`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/8*8)+8;
    localparam R_PAYLOAD_FORMANTTED_WIDTH = ((`AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/8*8)+8;
    localparam W_PAYLOAD_FORMANTTED_WIDTH = ((`AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/8*8)+8;
    localparam B_PAYLOAD_FORMANTTED_WIDTH = ((`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/8*8)+8;
    
    wire logging_arvalid;
    wire logging_arready;
    wire [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_ar_payload;
    wire logging_awvalid;
    wire logging_awready;
    wire [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_aw_payload;
    wire logging_rvalid;
    wire logging_rready;
    wire [R_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_r_payload;
    wire logging_wvalid;
    wire logging_wready;
    wire [W_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_w_payload;
    wire logging_bvalid;
    wire logging_bready;
    wire [B_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_b_payload;

    reg [63:0] target_cycles;
    always @(posedge clk ) begin
        if(rst)
            target_cycles <= 0;
        else
            target_cycles <= target_cycles + 1;
    end

    
    EmuTracePort #(.DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH)) AR_Channel (
        .clk(clk),
        .data(logging_ar_payload),
        .enable(logging_arvalid)
    );

    EmuTracePort #(.DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH)) AW_Channel (
        .clk(clk),
        .data(logging_aw_payload),
        .enable(logging_awvalid)
    );

    EmuTracePort #(.DATA_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH)) R_Channel (
        .clk(clk),
        .data(logging_r_payload),
        .enable(logging_rvalid)
    );


    EmuTracePort #(.DATA_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH)) W_Channel (
        .clk(clk),
        .data(logging_w_payload),
        .enable(logging_wvalid)
    );

    EmuTracePort #(.DATA_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH)) B_Channel (
        .clk(clk),
        .data(logging_b_payload),
        .enable(logging_bvalid)
    );

    axi_channel_logger #(
        .A_PAYLOAD_FORMANTTED_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .R_PAYLOAD_FORMANTTED_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH),
        .W_PAYLOAD_FORMANTTED_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH),
        .B_PAYLOAD_FORMANTTED_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    )axi_channel_logger (
        .clk(clk),
        .rst(rst),
        .logging_arvalid(logging_arvalid),
        .logging_arready(1),
        .logging_ar_payload(logging_ar_payload),
        .logging_awvalid(logging_awvalid),
        .logging_awready(1),
        .logging_aw_payload(logging_aw_payload),
        .logging_rvalid(logging_rvalid),
        .logging_rready(1),
        .logging_r_payload(logging_r_payload),
        .logging_wvalid(logging_wvalid),
        .logging_wready(1),
        .logging_w_payload(logging_w_payload),
        .logging_bvalid(logging_bvalid),
        .logging_bready(1),
        .logging_b_payload(logging_b_payload),
        `AXI4_CONNECT           (s_axi, s_axi),
        `AXI4_CONNECT           (m_axi, m_axi)
    );
endmodule
