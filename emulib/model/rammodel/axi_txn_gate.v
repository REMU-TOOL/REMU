`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

// Note: The master port does not comply with the AXI stability restrictions.
// An AXI register slice is required in the connection to a downstream slave.

module rammodel_axi_txn_gate #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(
    input                       clk,
    input                       resetn,

    `AXI4_SLAVE_IF              (s, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down
);

    wire s_arfire   = s_arvalid && s_arready;
    wire s_rfire    = s_rvalid && s_rready;
    wire s_awfire   = s_awvalid && s_awready;
    wire s_wfire    = s_wvalid && s_wready;
    wire s_bfire    = s_bvalid && s_bready;
    wire m_arfire   = m_arvalid && m_arready;
    wire m_rfire    = m_rvalid && m_rready;
    wire m_awfire   = m_awvalid && m_awready;
    wire m_wfire    = m_wvalid && m_wready;
    wire m_bfire    = m_bvalid && m_bready;

    reg arvalid;
    reg [`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)-1:0] ar_payload;

    always @(posedge clk) begin
        if (!resetn)
            arvalid <= 1'b0;
        else if (s_arfire)
            arvalid <= 1'b1;
        else if (s_rfire && s_rlast)
            arvalid <= 1'b0;
    end

    always @(posedge clk)
        if (s_arfire)
            ar_payload <= `AXI4_AR_PAYLOAD(s);

    reg awvalid;
    reg [`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)-1:0] aw_payload;

    always @(posedge clk) begin
        if (!resetn)
            awvalid <= 1'b0;
        else if (s_awfire)
            awvalid <= 1'b1;
        else if (s_bfire)
            awvalid <= 1'b0;
    end

    always @(posedge clk)
        if (s_awfire)
            aw_payload <= `AXI4_AW_PAYLOAD(s);

    reg [7:0] awlen;

    always @(posedge clk)
        if (s_awfire)
            awlen <= s_awlen;

    localparam [0:0]
        DO_AR   = 1'd0,
        DO_R    = 1'd1;

    (* emu_no_scanchain *) reg [0:0] r_state, r_state_next;

    always @(posedge clk) begin
        if (!resetn)
            r_state <= DO_AR;
        else
            r_state <= r_state_next;
    end

    localparam [1:0]
        DO_AW   = 2'd0,
        DO_W    = 2'd1,
        DO_B    = 2'd2;

    (* emu_no_scanchain *) reg [1:0] w_state, w_state_next;

    always @(posedge clk) begin
        if (!resetn)
            w_state <= DO_AW;
        else
            w_state <= w_state_next;
    end

    localparam [1:0]
        UP              = 2'd0,
        UP_PENDING      = 2'd1,
        DOWN            = 2'd2,
        DOWN_PENDING    = 2'd3;

    (* emu_no_scanchain *) reg [1:0] ctrl_state, ctrl_state_next;

    always @(posedge clk) begin
        if (!resetn)
            ctrl_state <= UP;
        else
            ctrl_state <= ctrl_state_next;
    end

    wire pending            = ctrl_state == UP_PENDING || ctrl_state == DOWN_PENDING;

    (* emu_no_scanchain *) reg [7:0] wlen;

    always @(posedge clk) begin
        if (!resetn)
            wlen <= 7'd0;
        else if (m_wfire) begin
            if (m_wlast)
                wlen <= 7'd0;
            else
                wlen <= wlen + 7'd1;
        end
    end

    // Counter for tracking AXI handshakes (in both NORMAL and RESUME state)
    // AR/AW = 0 R/W = 1,2,...,N B = N+1
    (* emu_no_scanchain *) reg [8:0] r_pos, r_pos_next;
    (* emu_no_scanchain *) reg [8:0] w_pos, w_pos_next;

    always @(posedge clk) begin
        if (!resetn)
            r_pos <= 9'd0;
        else
            r_pos <= r_pos_next;
    end

    always @(posedge clk) begin
        if (!resetn)
            w_pos <= 9'd0;
        else
            w_pos <= w_pos_next;
    end

    always @* begin
        if (m_rfire && m_rlast)
            r_pos_next = 9'd0;
        else if (m_arfire || m_rfire)
            r_pos_next = r_pos + 9'd1;
        else
            r_pos_next = r_pos;
    end

    always @* begin
        if (m_bfire)
            w_pos_next = 9'd0;
        else if (m_awfire || m_wfire)
            w_pos_next = w_pos + 9'd1;
        else
            w_pos_next = w_pos;
    end

    reg [8:0] r_pos_save, w_pos_save;

    always @(posedge clk) begin
        if (!resetn)
            r_pos_save <= 8'd0;
        else if (ctrl_state == UP && down_req)
            r_pos_save <= r_pos;
    end

    always @(posedge clk) begin
        if (!resetn)
            w_pos_save <= 8'd0;
        else if (ctrl_state == UP && down_req)
            w_pos_save <= w_pos;
    end

    always @* begin
        case (r_state)
            DO_AR:
                if (m_arfire)
                    r_state_next = DO_R;
                else
                    r_state_next = DO_AR;
            DO_R:
                if (m_rfire && m_rlast)
                    r_state_next = DO_AR;
                else
                    r_state_next = DO_R;
            default:
                r_state_next = DO_AR;
        endcase
    end

    always @* begin
        case (w_state)
            DO_AW:
                if (m_awfire)
                    w_state_next = DO_W;
                else
                    w_state_next = DO_AW;
            DO_W:
                if (m_wfire && m_wlast)
                    w_state_next = DO_B;
                else
                    w_state_next = DO_W;
            DO_B:
                if (m_bfire)
                    w_state_next = DO_AW;
                else
                    w_state_next = DO_B;
            default:
                w_state_next = DO_AW;
        endcase
    end

    always @* begin
        case (ctrl_state)
            UP:
                if (down_req)
                    ctrl_state_next = (r_state == DO_AR && w_state == DO_AW ? DOWN : DOWN_PENDING);
                else
                    ctrl_state_next = UP;
            DOWN_PENDING:
                if (m_rfire && m_rlast || m_bfire)
                    ctrl_state_next = DOWN;
                else
                    ctrl_state_next = DOWN_PENDING;
            DOWN:
                if (up_req)
                    ctrl_state_next = (arvalid || awvalid) ? UP_PENDING : UP;
                else
                    ctrl_state_next = DOWN;
            UP_PENDING:
                if (arvalid && r_pos_next == r_pos_save || awvalid && w_pos_next == w_pos_save)
                    ctrl_state_next = UP;
                else
                    ctrl_state_next = UP_PENDING;
            default:
                ctrl_state_next = UP;
        endcase
    end

    assign s_arready    = r_state == DO_AR && w_state == DO_AW && m_arready;
    assign s_awready    = r_state == DO_AR && w_state == DO_AW && !s_arvalid && m_awready;
    assign s_wready     = w_state == DO_W && m_wready;
    assign s_rvalid     = m_rvalid;
    assign s_rdata      = m_rdata;
    assign s_rlast      = m_rlast;
    assign s_rid        = m_rid;
    assign s_rresp      = m_rresp;
    assign s_bvalid     = m_bvalid;
    assign s_bid        = m_bid;
    assign s_bresp      = m_bresp;

    assign m_arvalid    = ctrl_state != DOWN && r_state == DO_AR && w_state == DO_AW && (s_arvalid || arvalid && pending);
    assign `AXI4_AR_PAYLOAD(m) = arvalid ? ar_payload : `AXI4_AR_PAYLOAD(s);
    assign m_rready     = r_state == DO_R && (s_rready || pending);
    assign m_awvalid    = ctrl_state != DOWN && r_state == DO_AR && w_state == DO_AW && (!s_arvalid && s_awvalid || awvalid && pending);
    assign `AXI4_AW_PAYLOAD(m) = awvalid ? aw_payload : `AXI4_AW_PAYLOAD(s);
    assign m_wvalid     = w_state == DO_W && (s_wvalid || pending);
    assign m_wdata      = s_wdata;
    assign m_wstrb      = ctrl_state == UP ? s_wstrb : {(DATA_WIDTH/8){1'b0}};
    assign m_wlast      = wlen == awlen;
    assign m_bready     = w_state == DO_B && (s_bready || pending);

    assign up           = ctrl_state == UP;
    assign down         = ctrl_state == DOWN;

`ifdef FORMAL

    reg f_past_valid;
    initial f_past_valid = 1'b0;

    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @*
        if (!f_past_valid)
            assume(!resetn);

    always @* begin
        assume(r_pos <='h101);
        assume(w_pos <='h102);
    end

    reg f_m_r_inflight, f_m_w_inflight;

    always @(posedge clk) begin
        if (!resetn) begin
            f_m_r_inflight <= 0;
            f_m_w_inflight <= 0;
        end
        else begin
            if (m_arfire) f_m_r_inflight <= 1;
            else if (m_rfire && m_rlast) f_m_r_inflight <= 0;
            if (m_awfire) f_m_w_inflight <= 1;
            else if (m_bfire) f_m_r_inflight <= 0;
        end
    end

    always @(posedge clk) begin
        if (resetn) begin
            // FSM state must be consistent with master interface
            assert(r_state == DO_AR || f_m_r_inflight);
            assert(w_state == DO_AW || f_m_w_inflight);
            // No concurrent read & write transactions
            assert(r_state == DO_AR || w_state == DO_AW);
        end
    end

`endif

endmodule
