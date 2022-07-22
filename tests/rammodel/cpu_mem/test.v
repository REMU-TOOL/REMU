`timescale 1ns / 1ps

`include "axi.vh"

module test(

    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

    input                       do_pause,
    input                       do_resume,

    output reg                  run_mode,
    input                       scan_mode,
    output                      idle,

    output                      trig,

    input                       ff_scan,
    input                       ff_dir,
    input   [63:0]              ff_sdi,
    output  [63:0]              ff_sdo,
    input                       ram_scan,
    input                       ram_dir,
    input   [63:0]              ram_sdi,
    output  [63:0]              ram_sdo,

    output reg  [63:0]          count,
    input                       count_write,
    input   [63:0]              count_wdata,

    input                       step_write,
    input   [63:0]              step_wdata,
    output                      step_trig,


    `AXI4_MASTER_IF             (host_axi, 32, 32, 1)

);

    wire tick;

    wire putchar_ren, putchar_rempty;
    wire [7:0] putchar_rdata;

    assign putchar_ren = 1'b1;

    always @(posedge host_clk)
        if (run_mode && !putchar_rempty)
            $write("%c", putchar_rdata);

    EMU_SYSTEM emu_dut(
        .host_clk       (host_clk),
        .host_rst       (host_rst),
        .ff_se          (ff_scan),
        .ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .ff_do          (ff_sdo),
        .ram_sr         (ram_scan_reset),
        .ram_se         (ram_scan),
        .ram_sd         (ram_dir),
        .ram_di         (ram_sdi),
        .ram_do         (ram_sdo),
        .target_reset_reset    (target_rst),
        .run_mode       (run_mode),
        .scan_mode      (scan_mode),
        .idle           (idle),
        .target_trap_trig_trigger       (trig),
        `AXI4_CONNECT       (target_uncore_u_rammodel_backend_host_axi, host_axi),
        .target_uncore_putchar_sink_ren    (putchar_ren),
        .target_uncore_putchar_sink_rdata  (putchar_rdata),
        .target_uncore_putchar_sink_rempty (putchar_rempty)
    );

    assign target_clk = emu_dut.target_clock_clock;
    assign tick = emu_dut.tick;

    always @(posedge host_clk)
        if (host_rst)
            count <= 64'd0;
        else if (count_write)
            count <= count_wdata;
        else if (run_mode && tick)
            count <= count + 64'd1;

    reg [63:0] step, step_next;

    always @(posedge host_clk)
        if (host_rst)
            step <= 64'd0;
        else
            step <= step_next;

    always @*
        if (step_write)
            step_next = step_wdata;
        else if (step == 64'd0)
            step_next = 64'd0;
        else if (run_mode && tick)
            step_next = step - 64'd1;
        else
            step_next = step;

    assign step_trig = step != 64'd0 && step_next == 64'd0;

    always @(posedge host_clk)
        if (host_rst)
            run_mode <= 1'b1;
        else if ((trig || step_trig || do_pause) && tick)
            run_mode <= 1'b0;
        else if (do_resume)
            run_mode <= 1'b1;

/*
    wire [31:0] cpuregs_x1  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[1];
    wire [31:0] cpuregs_x2  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[2];
    wire [31:0] cpuregs_x3  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[3];
    wire [31:0] cpuregs_x4  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[4];
    wire [31:0] cpuregs_x5  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[5];
    wire [31:0] cpuregs_x6  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[6];
    wire [31:0] cpuregs_x7  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[7];
    wire [31:0] cpuregs_x8  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[8];
    wire [31:0] cpuregs_x9  = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[9];
    wire [31:0] cpuregs_x10 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[10];
    wire [31:0] cpuregs_x11 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[11];
    wire [31:0] cpuregs_x12 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[12];
    wire [31:0] cpuregs_x13 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[13];
    wire [31:0] cpuregs_x14 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[14];
    wire [31:0] cpuregs_x15 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[15];
    wire [31:0] cpuregs_x16 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[16];
    wire [31:0] cpuregs_x17 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[17];
    wire [31:0] cpuregs_x18 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[18];
    wire [31:0] cpuregs_x19 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[19];
    wire [31:0] cpuregs_x20 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[20];
    wire [31:0] cpuregs_x21 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[21];
    wire [31:0] cpuregs_x22 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[22];
    wire [31:0] cpuregs_x23 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[23];
    wire [31:0] cpuregs_x24 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[24];
    wire [31:0] cpuregs_x25 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[25];
    wire [31:0] cpuregs_x26 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[26];
    wire [31:0] cpuregs_x27 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[27];
    wire [31:0] cpuregs_x28 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[28];
    wire [31:0] cpuregs_x29 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[29];
    wire [31:0] cpuregs_x30 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[30];
    wire [31:0] cpuregs_x31 = emu_dut.target.dut.\emu_top.dut_cpuregs .cpuregs[31];
*/

endmodule
