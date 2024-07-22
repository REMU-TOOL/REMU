module TraceBatch (
clk, rst,

tk0_valid, tk0_ready, tk0_enable, tk0_data,

tk1_valid, tk1_ready, tk1_enable, tk1_data,

tkn_valid, tkn_ready, tkn_enable, tkn_data,

ovalid, odata, olen, oready
);

    input   wire                clk;
    input   wire                rst;
    input   wire                tk0_valid;
    output  wire                tk0_ready;
    input   wire                tk0_enable;
    input   wire    [TRACE0_DATA_WDITH-1:0]      tk0_data;
    input   wire                tk1_valid;
    output  wire                tk1_ready;
    input   wire                tk1_enable;
    input   wire    [TRACE1_DATA_WDITH-1:0]      tk1_data;
    input   wire                tkn_valid;
    output  wire                tkn_ready;
    input   wire                tkn_enable;
    input   wire    [TRACEn_DATA_WDITH-1:0]      tkn_data;

    localparam INFO_WIDTH = 8;
    localparam END_INFO_VALUE = 'd128;
    localparam END_DATA_WIDTH = 64;

    function integer upALign;
        input integer n;
        input integer unit;
        upALign = (((unit-1) + n)/(unit))*unit;
    endfunction
    function integer packWidth;
        input integer n;
        packWidth = upALign(n, 8) + INFO_WIDTH;
    endfunction
    localparam AXI_DATA_WDITH = 64;
    localparam TRACE_NUM = 3;
    localparam TRACE0_DATA_WDITH = 28;
    localparam TRACE1_DATA_WDITH = 67;
    localparam TRACEn_DATA_WDITH = 13;
    localparam TRACE_TOTAL_WDITH = TRACE0_DATA_WDITH + TRACE1_DATA_WDITH + TRACEn_DATA_WDITH;
    wire [TRACE_NUM-1:0] inputValids = { tk0_valid, tk1_valid, tkn_valid };
    wire [TRACE_NUM-1:0] inputReadys = { tk0_ready, tk1_ready, tkn_ready };
    wire [TRACE_NUM-1:0] inputFires  = inputValids & inputReadys;

    localparam TOTAL_PACK_WIDTH = packWidth(TRACE0_DATA_WDITH) + packWidth(TRACE1_DATA_WDITH) + packWidth(TRACEn_DATA_WDITH);
    localparam ALIGN_TOTAL_PACK_WIDTH = upALign(TOTAL_PACK_WIDTH + INFO_WIDTH + END_DATA_WIDTH, AXI_DATA_WDITH);
    
    reg [$clog2(ALIGN_TOTAL_PACK_WIDTH)-1:0]  widthVec    [TRACE_NUM:0];
    reg [TRACE_NUM-1:0]         enableVec   [TRACE_NUM:0];
    reg                         bufferValid;

    reg [packWidth(TRACE0_DATA_WDITH)-1:0] pack0Vec [TRACE_NUM:0];
    reg [packWidth(TRACE0_DATA_WDITH)+packWidth(TRACE1_DATA_WDITH)-1:0] pack1Vec [TRACE_NUM:0];
    reg [packWidth(TRACE0_DATA_WDITH)+packWidth(TRACE1_DATA_WDITH)+packWidth(TRACEn_DATA_WDITH)-1:0] packnVec [TRACE_NUM:0];

    // ===========================================
    // ========= state assign logic ==============
    // ===========================================
    always @(posedge clk) begin
        if (!rst) begin
            bufferValid <= 0;
        end
        if (|inputFires) begin
            // should be 1'bn-1
            enableVec[0]  <= {
                tk0_enable,
                tk1_enable,
                tkn_enable
            };
            pack0Vec[0] <= { tk0_data, 8'd0 };
            pack1Vec[0] <= { 
                tk1_data, 8'd1,
                tk0_data, 8'd0  //TODO: TRACE0_DATA_WDITH'd0, 8'd0
            };
            packnVec[0] <= {
                tkn_data, 8'd2,
                tk1_data, 8'd1, //TODO: TRACE1_DATA_WDITH'd0, 8'd0
                tk0_data, 8'd0  //TODO: TRACE0_DATA_WDITH'd0, 8'd0
            };
            widthVec[0] <= 0;
            bufferValid <= tk0_enable || tk1_enable || tkn_enable;
        end
    end
    // ===========================================
    // ========== compress pipeline ==============
    // ===========================================
    wire    [TRACE_NUM:0]     pipeValid; 
    wire    [TRACE_NUM:0]     pipeReady;
    reg     [TRACE_NUM-1:0]   hasData;
    assign pipeValid[0] = bufferValid;
    assign tk0_ready = !bufferValid || pipeReady[0];
    assign tk1_ready = !bufferValid || pipeReady[0];
    assign tkn_ready = !bufferValid || pipeReady[0];
    generate
        for (genvar index = 0; index < TRACE_NUM; index ++) begin
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
                pack0Vec[1] <= pack0Vec[0];
                pack1Vec[1] <= pack1Vec[0];
                packnVec[1] <= packnVec[0];
                widthVec[1] <= widthVec[0] + packWidth(TRACE0_DATA_WDITH);
            end
            else begin
                pack0Vec[1] <= 0;
                pack1Vec[1] <= pack1Vec[0] >> packWidth(TRACE0_DATA_WDITH);
                packnVec[1] <= packnVec[0] >> packWidth(TRACE0_DATA_WDITH);
                widthVec[1] <= widthVec[0];
            end
        end
    end

    always @(posedge clk) begin
        if (pipeValid[1] && pipeReady[1]) begin
            enableVec[2] <= enableVec[1];
            if (enableVec[1][1]) begin
                pack0Vec[2] <= pack0Vec[1];
                pack1Vec[2] <= pack1Vec[1];
                packnVec[2] <= packnVec[1];
                widthVec[2] <= widthVec[1] + packWidth(TRACE1_DATA_WDITH);
            end
            else begin
                pack0Vec[2] <= pack0Vec[1];
                pack1Vec[2] <= 0;
                packnVec[2] <= packnVec[1] >> packWidth(TRACE1_DATA_WDITH);
                widthVec[2] <= widthVec[1];
            end
        end
    end

    always @(posedge clk) begin
        if (pipeValid[2] && pipeReady[2]) begin
            enableVec[3] <= enableVec[2];
            if (enableVec[2][2]) begin
                pack0Vec[3] <= pack0Vec[2];
                pack1Vec[3] <= pack1Vec[2];
                packnVec[3] <= packnVec[2];
                widthVec[3] <= widthVec[2] + packWidth(TRACEn_DATA_WDITH);
            end
            else begin
                pack0Vec[3] <= pack0Vec[2];
                pack1Vec[3] <= pack1Vec[2];
                packnVec[3] <= 0;
                widthVec[3] <= widthVec[2];
            end
        end
    end

    output wire ovalid = hasData[2];
    output wire [ALIGN_TOTAL_PACK_WIDTH-1:0] odata;
    output wire [$clog2(ALIGN_TOTAL_PACK_WIDTH)-1:0]olen;
    input  wire oready;
    assign pipeReady[3] = oready;
    wire [INFO_WIDTH-1:0]  endInfo = END_INFO_VALUE;
    wire [END_DATA_WIDTH-1:0] endData = 'd0;
    assign odata = pack0Vec[3] || pack1Vec[3] || packnVec[3] || ({endData, endInfo} <<  TOTAL_PACK_WIDTH);
    assign olen = widthVec[3] + 2; // end info and end data
    
endmodule