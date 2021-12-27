`timescale 1ns / 1ps

`include "axi.vh"

module rammodel_simple #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(
    input                       clk,
    input                       resetn,

    input                       dut_resetn,

    `AXI4_SLAVE_IF              (s_dut,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m_dram,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input                       pause,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down,

    output                      dut_stall
);

    `AXI4_WIRE(from_dut, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    axi_stall #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    s_dut_stall (
        .clk            (clk),
        .resetn         (resetn),
        `AXI4_CONNECT   (s, s_dut),
        `AXI4_CONNECT   (m, from_dut),
        .stall          (dut_stall || !dut_resetn)
    );

    `AXI4_WIRE(to_timing_model,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_WIRE(to_data_model,       ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    ready_valid_fork #(
        .DATA_WIDTH(`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    from_dut_fork_aw (
        .s_valid    (from_dut_awvalid),
        .s_ready    (from_dut_awready),
        .s_data     (`AXI4_AW_PAYLOAD(from_dut)),
        .m1_valid   (to_timing_model_awvalid),
        .m1_ready   (to_timing_model_awready),
        .m1_data    (`AXI4_AW_PAYLOAD(to_timing_model)),
        .m2_valid   (to_data_model_awvalid),
        .m2_ready   (to_data_model_awready),
        .m2_data    (`AXI4_AW_PAYLOAD(to_data_model))
    );

    ready_valid_fork #(
        .DATA_WIDTH(`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    from_dut_fork_w (
        .s_valid    (from_dut_wvalid),
        .s_ready    (from_dut_wready),
        .s_data     (`AXI4_W_PAYLOAD(from_dut)),
        .m1_valid   (to_timing_model_wvalid),
        .m1_ready   (to_timing_model_wready),
        .m1_data    (`AXI4_W_PAYLOAD(to_timing_model)),
        .m2_valid   (to_data_model_wvalid),
        .m2_ready   (to_data_model_wready),
        .m2_data    (`AXI4_W_PAYLOAD(to_data_model))
    );

    ready_valid_fork #(
        .DATA_WIDTH(`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    from_dut_fork_ar (
        .s_valid    (from_dut_arvalid),
        .s_ready    (from_dut_arready),
        .s_data     (`AXI4_AR_PAYLOAD(from_dut)),
        .m1_valid   (to_timing_model_arvalid),
        .m1_ready   (to_timing_model_arready),
        .m1_data    (`AXI4_AR_PAYLOAD(to_timing_model)),
        .m2_valid   (to_data_model_arvalid),
        .m2_ready   (to_data_model_arready),
        .m2_data    (`AXI4_AR_PAYLOAD(to_data_model))
    );

    assign from_dut_bvalid              = to_timing_model_bvalid;
    assign to_data_model_bready         = to_timing_model_bvalid && from_dut_bready;
    assign `AXI4_B_PAYLOAD(from_dut)    = `AXI4_B_PAYLOAD(to_data_model);

    assign from_dut_rvalid              = to_timing_model_rvalid;
    assign to_data_model_rready         = to_timing_model_rvalid && from_dut_rready;
    assign `AXI4_R_PAYLOAD(from_dut)    = `AXI4_R_PAYLOAD(to_data_model);

    rammodel_simple_timing_model #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
    )
    timing_model (
        .clk        (clk),
        .resetn     (resetn),
        .arvalid    (to_timing_model_arvalid),
        .arready    (to_timing_model_arready),
        .araddr     (to_timing_model_araddr),
        .arlen      (to_timing_model_arlen),
        .arsize     (to_timing_model_arsize),
        .arburst    (to_timing_model_arburst),
        .rvalid     (to_timing_model_rvalid),
        .rready     (to_timing_model_rready),
        .awvalid    (to_timing_model_awvalid),
        .awready    (to_timing_model_awready),
        .awaddr     (to_timing_model_awaddr),
        .awlen      (to_timing_model_awlen),
        .awsize     (to_timing_model_awsize),
        .awburst    (to_timing_model_awburst),
        .wvalid     (to_timing_model_wvalid),
        .wready     (to_timing_model_wready),
        .wlast      (to_timing_model_wlast),
        .bvalid     (to_timing_model_bvalid),
        .bready     (to_timing_model_bready),
        .stall      (dut_stall)
    );

    assign to_timing_model_bready = from_dut_bready;
    assign to_timing_model_rready = from_dut_rready;

    assign dut_stall =  pause ||
                        to_timing_model_bvalid && !to_data_model_bvalid ||
                        to_timing_model_rvalid && !to_data_model_rvalid;

    `AXI4_WIRE(from_gate, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    rammodel_axi_txn_gate #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    u_gate (
        .clk            (clk),
        .resetn         (resetn),
        `AXI4_CONNECT   (s, to_data_model),
        `AXI4_CONNECT   (m, from_gate),
        .up_req         (up_req),
        .down_req       (down_req),
        .up             (up),
        .down           (down)
    );

    (* emu_no_scanchain *)
    axi_register_slice #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    u_reg_slice (
        .clk            (clk),
        .resetn         (resetn),
        `AXI4_CONNECT   (s, from_gate),
        `AXI4_CONNECT   (m, m_dram)
    );

endmodule
