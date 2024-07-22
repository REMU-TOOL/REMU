module TraceBatch (
    input   wire                clk,
    input   wire                rst,
    
input   wire tk0_valid,
output  wire tk0_ready,
input   wire tk0_enable,
input   wire [6-1:0] tk0_data,
    

input   wire tk1_valid,
output  wire tk1_ready,
input   wire tk1_enable,
input   wire [34-1:0] tk1_data,
    

input   wire tk2_valid,
output  wire tk2_ready,
input   wire tk2_enable,
input   wire [26-1:0] tk2_data,
    

input   wire tk3_valid,
output  wire tk3_ready,
input   wire tk3_enable,
input   wire [74-1:0] tk3_data,
    

input   wire tk4_valid,
output  wire tk4_ready,
input   wire tk4_enable,
input   wire [93-1:0] tk4_data,
    
    output  wire                            ovalid, 
    output  wire    [384-1:0]    odata, 
    output  wire    [6-1:0]     olen, 
    input   wire                            oready
);

    localparam AXI_DATA_WDITH = 64;
    localparam TRACE0_DATA_WIDTH = 6;
localparam TRACE1_DATA_WIDTH = 34;
localparam TRACE2_DATA_WIDTH = 26;
localparam TRACE3_DATA_WIDTH = 74;
localparam TRACE4_DATA_WIDTH = 93;
    wire [5-1:0] inputValids = {tk4_valid, tk3_valid, tk2_valid, tk1_valid, tk0_valid};
    wire [5-1:0] inputReadys = {tk4_ready, tk3_ready, tk2_ready, tk1_ready, tk0_ready};
    wire [5-1:0] inputFires  = inputValids & inputReadys;

    reg [6-1:0]     widthVec        [5:0];
    reg [5-1:0]         enableVec       [5:0];
    reg                         bufferValid;

    reg [15:0] pack0Vec [5:0];
reg [63:0] pack1Vec [5:0];
reg [103:0] pack2Vec [5:0];
reg [191:0] pack3Vec [5:0];
reg [295:0] pack4Vec [5:0];

    // ===========================================
    // ========= state assign logic ==============
    // ===========================================
    always @(posedge clk) begin
        if (!rst) begin
            bufferValid <= 0;
        end
        if (|inputFires) begin
            enableVec[0] <= {tk4_enable, tk3_enable, tk2_enable, tk1_enable, tk0_enable};
            pack0Vec[0] <= {2'd0, tk0_data, 8'd0};

pack1Vec[0] <= {6'd0, tk1_data, 8'd1, 16'd0};

pack2Vec[0] <= {6'd0, tk2_data, 8'd2, 48'd0, 16'd0};

pack3Vec[0] <= {6'd0, tk3_data, 8'd3, 40'd0, 48'd0, 16'd0};

pack4Vec[0] <= {3'd0, tk4_data, 8'd4, 88'd0, 40'd0, 48'd0, 16'd0};

            widthVec[0] <= 0;
            bufferValid <= tk0_enable|| tk1_enable|| tk2_enable|| tk3_enable|| tk4_enable;
        end
    end
    // ===========================================
    // ========== compress pipeline ==============
    // ===========================================
    wire    [5:0]     pipeValid; 
    wire    [5:0]     pipeReady;
    reg     [5-1:0]   hasData;
    assign pipeValid[0] = bufferValid;
    // assign tk0_ready = !bufferValid || pipeReady[0];
    // assign tk1_ready = !bufferValid || pipeReady[0];
    // assign tkn_ready = !bufferValid || pipeReady[0];
    assign tk0_ready = !bufferValid || pipeReady[0];
assign tk1_ready = !bufferValid || pipeReady[1];
assign tk2_ready = !bufferValid || pipeReady[2];
assign tk3_ready = !bufferValid || pipeReady[3];
assign tk4_ready = !bufferValid || pipeReady[4];
    generate
        for (genvar index = 0; index < 5; index ++) begin
            always @(posedge clk ) begin
                if (!rst) begin
                    hasData[index] <= 0;
                end
                else if (pipeValid[index] && pipeReady[index]) begin
                    hasData[index] <= 1;
                end
                else if (pipeValid[index+1] && pipeReady[index+1]) begin
                    hasData[index] <= 0;
                end
            end
            assign pipeReady[index] = !hasData[index] || pipeReady[index+1];
            assign pipeValid[index+1] = hasData[index];
        end
    endgenerate

    
    always @(posedge clk) begin
        if (pipeValid[0] && pipeReady[0]) begin
            enableVec[1] <= enableVec[0];
            if (enableVec[0][0]) begin
                pack0Vec[0] <= pack0Vec[1];
pack1Vec[0] <= pack1Vec[1];
pack2Vec[0] <= pack2Vec[1];
pack3Vec[0] <= pack3Vec[1];
pack4Vec[0] <= pack4Vec[1];
                widthVec[1] <= widthVec[0] + 6'd2;
            end
            else begin
                pack0Vec[0] <= 0;
pack1Vec[0] <= pack1Vec[1] >> 16;
pack2Vec[0] <= pack2Vec[1] >> 16;
pack3Vec[0] <= pack3Vec[1] >> 16;
pack4Vec[0] <= pack4Vec[1] >> 16;
                widthVec[1] <= widthVec[0];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[1] && pipeReady[1]) begin
            enableVec[2] <= enableVec[1];
            if (enableVec[1][1]) begin
                pack0Vec[1] <= pack0Vec[2];
pack1Vec[1] <= pack1Vec[2];
pack2Vec[1] <= pack2Vec[2];
pack3Vec[1] <= pack3Vec[2];
pack4Vec[1] <= pack4Vec[2];
                widthVec[2] <= widthVec[1] + 6'd6;
            end
            else begin
                pack0Vec[1] <= pack0Vec[2];
pack1Vec[1] <= 0;
pack2Vec[1] <= pack2Vec[2] >> 48;
pack3Vec[1] <= pack3Vec[2] >> 48;
pack4Vec[1] <= pack4Vec[2] >> 48;
                widthVec[2] <= widthVec[1];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[2] && pipeReady[2]) begin
            enableVec[3] <= enableVec[2];
            if (enableVec[2][2]) begin
                pack0Vec[2] <= pack0Vec[3];
pack1Vec[2] <= pack1Vec[3];
pack2Vec[2] <= pack2Vec[3];
pack3Vec[2] <= pack3Vec[3];
pack4Vec[2] <= pack4Vec[3];
                widthVec[3] <= widthVec[2] + 6'd5;
            end
            else begin
                pack0Vec[2] <= pack0Vec[3];
pack1Vec[2] <= pack1Vec[3];
pack2Vec[2] <= 0;
pack3Vec[2] <= pack3Vec[3] >> 40;
pack4Vec[2] <= pack4Vec[3] >> 40;
                widthVec[3] <= widthVec[2];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[3] && pipeReady[3]) begin
            enableVec[4] <= enableVec[3];
            if (enableVec[3][3]) begin
                pack0Vec[3] <= pack0Vec[4];
pack1Vec[3] <= pack1Vec[4];
pack2Vec[3] <= pack2Vec[4];
pack3Vec[3] <= pack3Vec[4];
pack4Vec[3] <= pack4Vec[4];
                widthVec[4] <= widthVec[3] + 6'd11;
            end
            else begin
                pack0Vec[3] <= pack0Vec[4];
pack1Vec[3] <= pack1Vec[4];
pack2Vec[3] <= pack2Vec[4];
pack3Vec[3] <= 0;
pack4Vec[3] <= pack4Vec[4] >> 88;
                widthVec[4] <= widthVec[3];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[4] && pipeReady[4]) begin
            enableVec[5] <= enableVec[4];
            if (enableVec[4][4]) begin
                pack0Vec[4] <= pack0Vec[5];
pack1Vec[4] <= pack1Vec[5];
pack2Vec[4] <= pack2Vec[5];
pack3Vec[4] <= pack3Vec[5];
pack4Vec[4] <= pack4Vec[5];
                widthVec[5] <= widthVec[4] + 6'd13;
            end
            else begin
                pack0Vec[4] <= pack0Vec[5];
pack1Vec[4] <= pack1Vec[5];
pack2Vec[4] <= pack2Vec[5];
pack3Vec[4] <= pack3Vec[5];
pack4Vec[4] <= 0;
                widthVec[5] <= widthVec[4];
            end
        end
    end
      

    wire [64-1:0] endData = 'd0;
    assign pipeReady[5] = oready;
    assign ovalid = hasData[5-1];
    assign odata = { { 16'd0, endData, 8'd128 }, ({280'd0, pack0Vec[5]} | {232'd0, pack1Vec[5]} | {192'd0, pack2Vec[5]} | {104'd0, pack3Vec[5]} | pack4Vec[5]) };
    assign olen  = widthVec[5] + 6'd9;
endmodule

