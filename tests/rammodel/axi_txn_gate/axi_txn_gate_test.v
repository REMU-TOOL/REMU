`timescale 1ns / 1ps

module rammodel_axi_txn_gate_sim_wrapper #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(
    input                       clk,
    input                       resetn,

    `AXI4_SLAVE_IF              (s_dut, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m_dram, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input                       pause,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down,

    // for testbench use
    output                      dut_clk

);

    `AXI4_WIRE(from_dut, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_dut_stall_aw (
        .s_valid    (s_dut_awvalid),
        .s_ready    (s_dut_awready),
        .s_data     (`AXI4_AW_PAYLOAD(s_dut)),
        .m_valid    (from_dut_awvalid),
        .m_ready    (from_dut_awready),
        .m_data     (`AXI4_AW_PAYLOAD(from_dut)),
        .stall      (pause)
    );

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_dut_stall_w (
        .s_valid    (s_dut_wvalid),
        .s_ready    (s_dut_wready),
        .s_data     (`AXI4_W_PAYLOAD(s_dut)),
        .m_valid    (from_dut_wvalid),
        .m_ready    (from_dut_wready),
        .m_data     (`AXI4_W_PAYLOAD(from_dut)),
        .stall      (pause)
    );

    ready_valid_stall_m #(
        .DATA_WIDTH(`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_dut_stall_b (
        .m_valid    (s_dut_bvalid),
        .m_ready    (s_dut_bready),
        .m_data     (`AXI4_B_PAYLOAD(s_dut)),
        .s_valid    (from_dut_bvalid),
        .s_ready    (from_dut_bready),
        .s_data     (`AXI4_B_PAYLOAD(from_dut)),
        .stall      (pause)
    );

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_dut_stall_ar (
        .s_valid    (s_dut_arvalid),
        .s_ready    (s_dut_arready),
        .s_data     (`AXI4_AR_PAYLOAD(s_dut)),
        .m_valid    (from_dut_arvalid),
        .m_ready    (from_dut_arready),
        .m_data     (`AXI4_AR_PAYLOAD(from_dut)),
        .stall      (pause)
    );

    ready_valid_stall_m #(
        .DATA_WIDTH(`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_dut_stall_r (
        .m_valid    (s_dut_rvalid),
        .m_ready    (s_dut_rready),
        .m_data     (`AXI4_R_PAYLOAD(s_dut)),
        .s_valid    (from_dut_rvalid),
        .s_ready    (from_dut_rready),
        .s_data     (`AXI4_R_PAYLOAD(from_dut)),
        .stall      (pause)
    );

    rammodel_axi_txn_gate #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )
    uut (
        .clk                    (clk),
        .resetn                 (resetn),
        `AXI4_CONNECT           (s, from_dut),
        `AXI4_CONNECT           (m, m_dram),
        .up_req                 (up_req),
        .down_req               (down_req),
        .up                     (up),
        .down                   (down)
    );

    reg en_latch;
    always @(clk or pause)
        if (~clk)
            en_latch = !pause;
    assign dut_clk = clk & en_latch;

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile(`DUMPFILE);
            $dumpvars();
        end
    end

endmodule
