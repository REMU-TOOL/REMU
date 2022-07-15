`timescale 1 ns / 1 ps

module ffpause(
    (* __emu_extern_intf = "test" *)
    input en,
    (* __emu_extern_intf = "test" *)
    input [31:0] d,
    (* __emu_extern_intf = "test" *)
    output reg [31:0] q
);

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    always @(posedge clk) begin
        if (rst) q <= 32'd0;
        else if (en) q <= d;
    end

endmodule
