`timescale 1 ns / 1 ps

module srsw(
    (* __emu_extern_intf = "test" *)
    input                   ren,
    (* __emu_extern_intf = "test" *)
    input   [2:0]           raddr,
    (* __emu_extern_intf = "test" *)
    output  [79:0]          rdata,
    (* __emu_extern_intf = "test" *)
    input                   wen,
    (* __emu_extern_intf = "test" *)
    input   [2:0]           waddr,
    (* __emu_extern_intf = "test" *)
    input   [79:0]          wdata
);

    wire clk;
    EmuClock clock(.clock(clk));

    mem #(
        .WIDTH(80),
        .DEPTH(8),
        .OFFSET(0),
        .SYNCREAD(1)
    )
    u_mem (
        .clk(clk),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

endmodule
