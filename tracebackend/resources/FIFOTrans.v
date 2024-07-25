module FIFOTrans #(
    parameter IN_WIDTH  = 104,
    parameter OUT_WIDTH = 64
) (
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          ivalid,
    output wire                          iready,
    input  wire [          IN_WIDTH-1:0] idata,
    input  wire [$clog2(IN_WIDTH/8)-1:0] ilen,
    output wire                          ovalid,
    input  wire                          oready,
    output wire [         OUT_WIDTH-1:0] odata
);
  reg [IN_WIDTH-1:0] dataBuffer;
  reg [$clog2(IN_WIDTH/8)-1:0] lenBuffer;
  reg [$clog2(IN_WIDTH/8)-1:0] count;
  reg busy;
  always @(posedge clk) begin
    if (rst) begin
      busy <= 'b0;
    end else if (ivalid && iready) begin
      busy <= 'b1;
      count <= 'd0;
      dataBuffer <= idata;
      lenBuffer <= ilen;
    end else if (ovalid && oready) begin
      if (count < lenBuffer) begin
        dataBuffer <= dataBuffer >> OUT_WIDTH;
        count <= count + (OUT_WIDTH/8);
      end else begin
        busy <= 'b0;
      end
    end
  end
  assign ovalid = busy;
  assign odata  = dataBuffer[OUT_WIDTH-1:0];
endmodule
