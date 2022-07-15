`timescale 1 ns / 1 ps

module srsw2(
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

    reg [79:0] mem [7:0];
    reg [2:0] raddr_reg;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        raddr_reg <= raddr;
    end

    assign rdata = mem[raddr_reg];

endmodule
