`timescale 1ns / 1ps

module emulib_axis_width_downsizer #(
    parameter   S_TDATA_BYTES   = 1,
    parameter   M_TDATA_BYTES   = 1,
    parameter   BYTE_WIDTH      = 8
)(
    input  wire                                 clk,
    input  wire                                 rst,

    input  wire                                 s_tvalid,
    output wire                                 s_tready,
    input  wire [BYTE_WIDTH*S_TDATA_BYTES-1:0]  s_tdata,
    input  wire [S_TDATA_BYTES-1:0]             s_tkeep,
    input  wire                                 s_tlast,

    output wire                                 m_tvalid,
    input  wire                                 m_tready,
    output wire [BYTE_WIDTH*M_TDATA_BYTES-1:0]  m_tdata,
    output wire [M_TDATA_BYTES-1:0]             m_tkeep,
    output wire                                 m_tlast
);

    initial begin
        if (S_TDATA_BYTES % M_TDATA_BYTES != 0) begin
            $display("ERROR: S_TDATA_BYTES(%d) is not a multiple of M_TDATA_BYTES(%d) (instance %m)",
                S_TDATA_BYTES, M_TDATA_BYTES);
            $finish;
        end
    end

    localparam RATIO = S_TDATA_BYTES / M_TDATA_BYTES;
    localparam S_TDATA_WIDTH = S_TDATA_BYTES * BYTE_WIDTH;
    localparam M_TDATA_WIDTH = M_TDATA_BYTES * BYTE_WIDTH;

    localparam [0:0]
        STATE_XFER_S    = 1'b0,
        STATE_XFER_M    = 1'b1;

    reg [0:0] state, state_next;

    reg [$clog2(RATIO)-1:0] slice_cnt;
    reg [S_TDATA_WIDTH-1:0] buf_tdata;
    reg [S_TDATA_BYTES-1:0] buf_tkeep;
    reg buf_tlast;

    wire s_fire = s_tvalid && s_tready;
    wire m_fire = m_tvalid && m_tready;
    wire slice_cnt_going_empty = slice_cnt == 0;
    wire buf_tkeep_going_empty = ~|buf_tkeep[S_TDATA_BYTES-1:M_TDATA_BYTES];

    always @(posedge clk) begin
        if (rst)
            state <= STATE_XFER_S;
        else
            state <= state_next;
    end

    always @* begin
        state_next = STATE_XFER_S;
        case (state)
            STATE_XFER_S:   state_next = s_fire ? STATE_XFER_M : STATE_XFER_S;
            STATE_XFER_M:   state_next = (m_fire && (slice_cnt_going_empty || m_tlast)) ? STATE_XFER_S : STATE_XFER_M;
        endcase
    end

    always @(posedge clk) begin
        if (rst || s_fire)
            slice_cnt <= RATIO - 1;
        else if (m_fire)
            slice_cnt <= slice_cnt_going_empty ? 0 : slice_cnt - 1;
    end

    always @(posedge clk) begin
        if (s_fire)
            buf_tdata <= s_tdata;
        else if (m_fire)
            buf_tdata <= buf_tdata >> M_TDATA_WIDTH;
    end

    always @(posedge clk) begin
        if (s_fire)
            buf_tkeep <= s_tkeep;
        else if (m_fire)
            buf_tkeep <= buf_tkeep >> M_TDATA_BYTES;
    end

    always @(posedge clk) begin
        if (s_fire)
            buf_tlast <= s_tlast;
    end

    assign s_tready = state == STATE_XFER_S;
    assign m_tvalid = state == STATE_XFER_M;
    assign m_tdata  = buf_tdata;
    assign m_tkeep  = buf_tkeep;
    assign m_tlast  = buf_tlast && buf_tkeep_going_empty;

endmodule
