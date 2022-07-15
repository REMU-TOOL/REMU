`timescale 1 ns / 1 ps

module srsw_rdata(
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

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    reg [31:0] mem [3:0], o;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        if (rst) o <= 32'd0;
        else if (ren) o <= mem[raddr];
    end

    assign rdata = o;

endmodule
