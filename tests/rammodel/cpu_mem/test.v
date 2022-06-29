`timescale 1ns / 1ps

`include "axi.vh"

module test(

    input                       clk,
    input                       resetn,

    output                      trig,

    output reg                  pause,
    input                       do_pause,
    input                       do_resume,

    input                       ff_scan,
    input                       ff_dir,
    input   [63:0]              ff_sdi,
    output  [63:0]              ff_sdo,
    input                       ram_scan,
    input                       ram_dir,
    input   [63:0]              ram_sdi,
    output  [63:0]              ram_sdo,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down,

    // for testbench use
    output                      dut_clk,

    output reg  [63:0]          count,
    input                       count_write,
    input   [63:0]              count_wdata,

    input                       step_write,
    input   [63:0]              step_wdata,
    output                      step_trig,


    `AXI4_MASTER_IF             (host_axi, 32, 32, 1),
    `AXI4_MASTER_IF             (lsu_axi, 32, 32, 1)

);

    //reg clk = 0, rst = 1;
    wire rst = !resetn;
    //reg pause = 0;
    //reg ff_scan = 0, ff_dir = 0;
    //reg [63:0] ff_sdi = 0;
    //wire [63:0] ff_sdo;
    //reg ram_scan = 0, ram_dir = 0;
    //reg [63:0] ram_sdi = 0;
    //wire [63:0] ram_sdo;

    wire dut_stall;

    wire dut_clk, dut_clk_en;
    ClockGate clk_gate(
        .CLK(clk),
        .EN(dut_clk_en),
        .OCLK(dut_clk)
    );

    wire emu_dut_ff_clk, emu_dut_ff_clk_en;
    ClockGate dut_ff_clk_gate(
        .CLK(clk),
        .EN(emu_dut_ff_clk_en),
        .OCLK(emu_dut_ff_clk)
    );

    wire emu_dut_ram_clk, emu_dut_ram_clk_en;
    ClockGate dut_ram_clk_gate(
        .CLK(clk),
        .EN(emu_dut_ram_clk_en),
        .OCLK(emu_dut_ram_clk)
    );

    wire putchar_valid, putchar_ready;
    wire [7:0] putchar_data;

    assign putchar_ready = 1'b1;

    always @(posedge clk)
        if (dut_clk_en && putchar_valid)
            $write("%c", putchar_data);

    EMU_DUT emu_dut(
        .emu_host_clk       (clk),
        .emu_host_rst       (rst),
        .emu_ff_se          (ff_scan),
        .emu_ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .emu_ff_do          (ff_sdo),
        .emu_ram_se         (ram_scan),
        .emu_ram_sd         (ram_dir),
        .emu_ram_di         (ram_sdi),
        .emu_ram_do         (ram_sdo),
        .emu_dut_ff_clk     (emu_dut_ff_clk),
        .emu_dut_ram_clk    (emu_dut_ram_clk),
        .emu_dut_rst        (rst),
        .emu_dut_trig       (trig),
        .emu_target_fire    (!pause && !dut_stall),
        .emu_stall          (dut_stall),
        .emu_up_req         (up_req),
        .emu_down_req       (down_req),
        .emu_up_stat        (up),
        .emu_down_stat      (down),
        `AXI4_CONNECT       (uncore_u_rammodel_host_axi, host_axi),
        `AXI4_CONNECT_NO_ID (uncore_u_rammodel_lsu_axi, lsu_axi),
        .emu_putchar_valid              (putchar_valid),
        .emu_putchar_ready              (putchar_ready),
        .emu_putchar_data               (putchar_data)
    );

    assign lsu_axi_arid = 0;
    assign lsu_axi_awid = 0;

    assign dut_clk_en = !pause && !dut_stall;
    assign emu_dut_ff_clk_en = !pause && !dut_stall || ff_scan;
    assign emu_dut_ram_clk_en = !pause && !dut_stall || ram_scan;

    always @(posedge clk)
        if (!resetn)
            count <= 64'd0;
        else if (count_write)
            count <= count_wdata;
        else if (dut_clk_en)
            count <= count + 64'd1;

    reg [63:0] step, step_next;

    always @(posedge clk)
        if (!resetn)
            step <= 64'd0;
        else
            step <= step_next;

    always @*
        if (step_write)
            step_next = step_wdata;
        else if (step == 64'd0)
            step_next = 64'd0;
        else if (dut_clk_en)
            step_next = step - 64'd1;

    assign step_trig = step != 64'd0 && step_next == 64'd0;

    always @(posedge clk)
        if (!resetn)
            pause <= 1'b0;
        else if (trig || step_trig || do_pause)
            pause <= 1'b1;
        else if (do_resume)
            pause <= 1'b0;

endmodule
