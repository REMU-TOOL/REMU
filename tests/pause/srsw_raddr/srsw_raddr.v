`timescale 1 ns / 1 ps

module srsw_raddr(
    (* __emu_extern_intf = "test" *)
    input wen,
    (* __emu_extern_intf = "test" *)
    input [1:0] waddr,
    (* __emu_extern_intf = "test" *)
    input [31:0] wdata,
    (* __emu_extern_intf = "test" *)
    input ren,
    (* __emu_extern_intf = "test" *)
    input [1:0] raddr,
    (* __emu_extern_intf = "test" *)
    output [31:0] rdata
);

    wire clk;
    EmuClock clock(.clock(clk));

    reg [31:0] mem [3:0];
    reg [1:0] raddr_reg;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        raddr_reg <= raddr;
    end

    assign rdata = mem[raddr_reg];

endmodule
