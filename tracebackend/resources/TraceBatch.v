module {moduleName} (
    input   wire                clk,
    input   wire                rst,
    {tracePortDefine}
    output  wire                            ovalid, 
    output  wire    [{outDataWidth}-1:0]    odata, 
    output  wire    [{outLenWidth}-1:0]     olen, 
    input   wire                            oready
);

    localparam AXI_DATA_WDITH = 64;
    {traceWidthParams}
    wire [{traceNR}-1:0] inputValids = {inputValids};
    wire [{traceNR}-1:0] inputReadys = {inputReadys};
    wire [{traceNR}-1:0] inputFires  = inputValids & inputReadys;

    reg [{outLenWidth}-1:0]     widthVec        [{traceNR}:0];
    reg [{traceNR}-1:0]         enableVec       [{traceNR}:0];
    reg                         bufferValid;
    wire    [{traceNR}:0]       pipeValid; 
    wire    [{traceNR}:0]       pipeReady;
    reg     [{traceNR}-1:0]     hasData;

    assign pipeValid[0] = bufferValid;

    {packVecDefine}

    // ===========================================
    // ========= state assign logic ==============
    // ===========================================
    always @(posedge clk) begin
        if (!rst) begin
            bufferValid <= 0;
        end
        if (|inputFires) begin
            enableVec[0] <= {enableVecInit};
            {packVecInit}
            widthVec[0] <= 0;
            bufferValid <= {bufferValidInit};
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
        for (index = 0; index < {traceNR}; index ++) begin
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

    {pipeline}

    wire [{markDataWidth}-1:0] markData = 'd0;
    assign pipeReady[{traceNR}] = oready;
    assign ovalid = hasData[{traceNR}-1];
    assign odata = {pipeDataOut};
    assign olen  = {pipeLenOut};
endmodule