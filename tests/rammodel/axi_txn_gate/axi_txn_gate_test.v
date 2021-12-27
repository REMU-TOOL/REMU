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
        .stall          (pause)
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
