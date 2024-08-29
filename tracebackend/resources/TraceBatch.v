module {moduleName} (
    input   wire                host_clk,
    input   wire                host_rst,
    input   wire    [63:0]      tick_cnt,
    {tracePortDefine}
    output  wire                            ovalid, 
    output  wire    [{outDataWidth}-1:0]    odata, 
    output  wire    [{outLenWidth}-1:0]     olen, 
    input   wire                            oready
);

    {traceWidthParams}
    wire [{traceNR}-1:0] inputValids = {inputValids};
    wire [{traceNR}-1:0] inputReadys = {inputReadys};
    wire [{traceNR}-1:0] inputFires  = inputValids & inputReadys;

    reg [{outLenWidth}-1:0]     widthVec        [{traceNR}:0];
    reg [{traceNR}-1:0]         enableVec       [{traceNR}:0];
    reg [31:0]                  tickDelta       [{traceNR}:0];
    reg                         bufferValid;
    wire    [{traceNR}:0]       pipeValid; 
    wire    [{traceNR}:0]       pipeReady;
    reg     [{traceNR}-1:0]     hasData;

    assign pipeValid[0] = bufferValid;

    {packVecDefine}

    reg [63:0] last_tick_cnt;
    localparam TICK_MAX_INTERVAL = 32'hffff;
    wire is_max_interval = last_tick_cnt + TICK_MAX_INTERVAL == tick_cnt;
    // ===========================================
    // ========= state assign logic ==============
    // ===========================================
    always @(posedge host_clk) begin
        if (host_rst) begin
            bufferValid <= 0;
            last_tick_cnt <= 0;
        end
        if (|inputFires) begin
            enableVec[0] <= {enableVecInit};
            {packVecInit}
            widthVec[0] <= 0;
            bufferValid <= {bufferValidInit};
            tickDelta[0] <= tick_cnt - last_tick_cnt;
        end
        else if (last_tick_cnt + TICK_MAX_INTERVAL == tick_cnt) begin
            enableVec[0] <= 'd0;
            widthVec[0]  <= 'd0;
            bufferValid  <= 'd1;
            tickDelta[0] <= TICK_MAX_INTERVAL;
        end
        else if (pipeValid[0] && pipeReady[0]) begin
            bufferValid <= 0;
        end
    end
    // ===========================================
    // ========== compress pipeline ==============
    // ===========================================
    // assign tk0_ready = !bufferValid || pipeReady[0];
    // assign tk1_ready = !bufferValid || pipeReady[0];
    // assign tkn_ready = !bufferValid || pipeReady[0];
    {asisgnTraceReady}
    genvar index;
    generate
        for (index = 0; index < {traceNR}; index = index + 1) begin
            always @(posedge host_clk) begin
                if (host_rst) begin
                    hasData[index] <= 0;
                end
                else if (pipeValid[index] && pipeReady[index]) begin
                    hasData[index] <= 1;
                    tickDelta[index+1] <= tickDelta[index];
                end
                else if (pipeValid[index+1] && pipeReady[index+1]) begin
                    hasData[index] <= 0;
                end
            end
            assign pipeReady[index] = !hasData[index] || pipeReady[index+1];
            assign pipeValid[index+1] = hasData[index];
        end
    endgenerate

    {pipeline}

    assign pipeReady[{traceNR}] = oready;
    assign ovalid = hasData[{traceNR}-1];
    assign odata = {pipeDataOut};
    assign olen  = {pipeLenOut};
endmodule