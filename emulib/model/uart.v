`timescale 1ns / 1ps

`include "axi.vh"

(* __emu_model_type = "uart" *)
module EmuUart #(
    parameter   RX_FIFO_DEPTH   = 16,
    parameter   TX_FIFO_DEPTH   = 16
)(
    input  wire         clk,
    input  wire         rst,

    `AXI4LITE_SLAVE_IF  (s_axilite, 4, 32)
);

    // Register Space
    // 0x00 Rx FIFO
    // 0x04 Tx FIFO
    // 0x08 STAT_REG
    // 0x0C CTRL_REG

    // TODO: interrupt

    wire         tx_valid;
    wire [7:0]   tx_ch;
    wire         rx_valid;
    wire [7:0]   rx_ch;

    EmuUartRxTxImp rx_tx_imp (
        .clk        (clk),
        .tx_valid   (tx_valid),
        .tx_ch      (tx_ch),
        .rx_valid   (rx_valid),
        .rx_ch      (rx_ch),
        // the following connections will be rewritten by transformation process
        ._tx_valid  (),
        ._tx_ch     (),
        ._rx_valid  (1'b0),
        ._rx_ch     (8'd0)
    );

    // Rx logic

    wire rx_fifo_clear;
    wire rx_fifo_valid;
    wire rx_fifo_ready;
    wire [7:0] rx_fifo_data;
    wire rx_fifo_not_full;

    emulib_ready_valid_fifo #(
        .WIDTH  (8),
        .DEPTH  (RX_FIFO_DEPTH)
    ) rx_fifo (
        .clk    (clk),
        .rst    (rst || rx_fifo_clear),
        .ivalid (rx_valid),
        .iready (rx_fifo_not_full),
        .idata  (rx_ch),
        .ovalid (rx_fifo_valid),
        .oready (rx_fifo_ready),
        .odata  (rx_fifo_data)
    );

    // Tx logic

    wire tx_fifo_clear;
    wire tx_fifo_valid;
    wire tx_fifo_ready;
    wire [7:0] tx_fifo_data;

    emulib_ready_valid_fifo #(
        .WIDTH  (8),
        .DEPTH  (TX_FIFO_DEPTH)
    ) tx_fifo (
        .clk    (clk),
        .rst    (rst || tx_fifo_clear),
        .ivalid (tx_fifo_valid),
        .iready (tx_fifo_ready),
        .idata  (tx_fifo_data),
        .ovalid (tx_valid),
        .oready (1'b1),
        .odata  (tx_ch)
    );

    // Status bits

    wire stat_clear;

    reg overrun_err;

    always @(posedge clk) begin
        if (rst)
            overrun_err <= 1'b0;
        else if (rx_valid && !rx_fifo_not_full)
            overrun_err <= 1'b1;
        else if (stat_clear)
            overrun_err <= 1'b0;
    end

    // AXI lite read logic

    localparam [1:0]
        R_STATE_AXI_AR  = 2'd0,
        R_STATE_READ    = 2'd1,
        R_STATE_AXI_R   = 2'd2;

    reg [1:0] r_state, r_state_next;

    always @(posedge clk) begin
        if (rst)
            r_state <= R_STATE_AXI_AR;
        else
            r_state <= r_state_next;
    end

    always @* begin
        case (r_state)
            R_STATE_AXI_AR: r_state_next = s_axilite_arvalid ? R_STATE_READ : R_STATE_AXI_AR;
            R_STATE_READ:   r_state_next = R_STATE_AXI_R;
            R_STATE_AXI_R:  r_state_next = s_axilite_rready ? R_STATE_AXI_AR : R_STATE_AXI_R;
            default:        r_state_next = R_STATE_AXI_AR;
        endcase
    end

    reg [3:0] read_addr;

    always @(posedge clk)
        if (s_axilite_arvalid && s_axilite_arready)
            read_addr <= s_axilite_araddr;

    reg [31:0] read_data;

    always @(posedge clk) begin
        if (r_state == R_STATE_READ) begin
            case (read_addr[3:2])
                2'd0:   read_data <= {24'd0, rx_fifo_data};
                2'd2:   read_data <= {26'd0, overrun_err, 1'b0, !tx_fifo_ready, !tx_fifo_valid, !rx_fifo_not_full, rx_fifo_valid};
            endcase
        end
    end

    wire r_rx_fifo  = read_addr[3:2] == 2'd0;
    wire r_stat_reg = read_addr[3:2] == 2'd2;

    reg [1:0] read_resp;

    always @(posedge clk) begin
        if (rst)
            read_resp <= 2'b00;
        else if (r_state == R_STATE_READ)
            read_resp <= (r_rx_fifo && !rx_fifo_valid) ? 2'b10 : 2'b00;
    end

    assign rx_fifo_ready    = r_state == R_STATE_READ && r_rx_fifo;
    assign stat_clear       = r_state == R_STATE_READ && r_stat_reg;

    assign s_axilite_arready    = r_state == R_STATE_AXI_AR;
    assign s_axilite_rvalid     = r_state == R_STATE_AXI_R;
    assign s_axilite_rdata      = read_data;
    assign s_axilite_rresp      = read_resp;

    // AXI lite write logic

    localparam [1:0]
        W_STATE_AXI_AW  = 2'd0,
        W_STATE_AXI_W   = 2'd1,
        W_STATE_WRITE   = 2'd2,
        W_STATE_AXI_B   = 2'd3;

    reg [1:0] w_state, w_state_next;

    always @(posedge clk) begin
        if (rst)
            w_state <= W_STATE_AXI_AW;
        else
            w_state <= w_state_next;
    end

    always @* begin
        case (w_state)
            W_STATE_AXI_AW: w_state_next = s_axilite_awvalid ? W_STATE_AXI_W : W_STATE_AXI_AW;
            W_STATE_AXI_W:  w_state_next = s_axilite_wvalid ? W_STATE_WRITE : W_STATE_AXI_W;
            W_STATE_WRITE:  w_state_next = W_STATE_AXI_B;
            W_STATE_AXI_B:  w_state_next = s_axilite_bready ? W_STATE_AXI_AW : W_STATE_AXI_B;
            default:        w_state_next = W_STATE_AXI_AW;
        endcase
    end

    reg [3:0] write_addr;

    always @(posedge clk)
        if (s_axilite_awvalid && s_axilite_awready)
            write_addr <= s_axilite_awaddr;

    reg [31:0] write_data;
    reg [3:0] write_strb;

    always @(posedge clk) begin
        if (s_axilite_wvalid && s_axilite_wready) begin
            write_data <= s_axilite_wdata;
            write_strb <= s_axilite_wstrb;
        end
    end

    wire w_tx_fifo  = write_addr[3:2] == 2'd1 && write_strb[0];
    wire w_ctrl_reg = write_addr[3:2] == 2'd3 && write_strb[0];

    reg [1:0] write_resp;

    always @(posedge clk) begin
        if (rst)
            write_resp <= 2'b00;
        else if (w_state == W_STATE_WRITE)
            write_resp <= (w_tx_fifo && !tx_fifo_ready) ? 2'b10 : 2'b00;
    end

    assign tx_fifo_data = write_data[7:0];

    assign tx_fifo_valid = w_state == W_STATE_WRITE && w_tx_fifo;
    assign tx_fifo_clear = w_state == W_STATE_WRITE && w_ctrl_reg && write_data[0];
    assign rx_fifo_clear = w_state == W_STATE_WRITE && w_ctrl_reg && write_data[1];

    assign s_axilite_awready    = w_state == W_STATE_AXI_AW;
    assign s_axilite_wready     = w_state == W_STATE_AXI_W;
    assign s_axilite_bvalid     = w_state == W_STATE_AXI_B;
    assign s_axilite_bresp      = write_resp;

endmodule
