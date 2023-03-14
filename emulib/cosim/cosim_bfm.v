`timescale 1ns / 1ps

`include "axi.vh"

module cosim_bfm #(
    parameter   MEM_ADDR_WIDTH  = 32,
    parameter   MEM_DATA_WIDTH  = 64,
    parameter   MEM_STRB_WIDTH  = MEM_DATA_WIDTH / 8,
    parameter   MEM_ID_WIDTH    = 1,
    parameter   MEM_SIZE        = 64'h40000000
)(
    input  wire         clk,
    input  wire         rst,
    `AXI4_SLAVE_IF      (mem_axi, MEM_ADDR_WIDTH, MEM_DATA_WIDTH, MEM_ID_WIDTH),
    `AXI4LITE_MASTER_IF (mmio_axi, 32, 32)
);

    localparam ADDR_MASK    = {MEM_ADDR_WIDTH{1'b1}};

    integer result;

    initial begin
        if (MEM_ADDR_WIDTH < 1 || MEM_ADDR_WIDTH > 64) begin
            $display("%m: MEM_ADDR_WIDTH must be in [1,64]");
            $finish;
        end
        if (MEM_DATA_WIDTH != 8 && MEM_DATA_WIDTH != 16 &&
            MEM_DATA_WIDTH != 32 && MEM_DATA_WIDTH != 64) begin
            $display("%m: MEM_DATA_WIDTH must be 8, 16, 32 or 64");
            $finish;
        end
        if (MEM_ID_WIDTH < 1) begin
            $display("%m: MEM_ID_WIDTH must be greater than 0");
            $finish;
        end
        if (MEM_SIZE % 'h1000 != 0) begin
            $display("%m: MEM_SIZE must be aligned to 4KB");
            $finish;
        end
        result = $cosim_new(MEM_SIZE);
    end

    integer i;

    localparam BURST_INCR   = 2'b01;
    localparam BURST_WRAP   = 2'b10;

    localparam RESP_OK      = 2'b00;
    localparam RESP_SLVERR  = 2'b10;

    localparam STATE_IDLE   = 0;
    localparam STATE_AR     = 1;
    localparam STATE_R      = 2;
    localparam STATE_AW     = 3;
    localparam STATE_W      = 4;
    localparam STATE_B      = 5;

    // Memory BFM

    integer mem_r_state;

    reg [MEM_ID_WIDTH-1:0]      mem_read_id;
    reg [MEM_ADDR_WIDTH-1:0]    mem_read_addr;
    reg [7:0]                   mem_read_len;
    reg [2:0]                   mem_read_size;
    reg [1:0]                   mem_read_burst;
    reg [MEM_ADDR_WIDTH-1:0]    mem_read_addr_wrap_lb;
    reg [MEM_ADDR_WIDTH-1:0]    mem_read_addr_wrap_ub;

    reg [MEM_DATA_WIDTH-1:0]    mem_axi_rdata_reg;
    reg [MEM_DATA_WIDTH-1:0]    temp_r_data;

    always @(posedge clk) begin
        if (rst) begin
            mem_r_state <= STATE_AR;
        end
        else begin
            case (mem_r_state)
                STATE_AR: begin
                    if (mem_axi_arvalid) begin
                        mem_r_state     <= STATE_R;
                        mem_read_id     <= mem_axi_arid;
                        mem_read_len    <= mem_axi_arlen;
                        mem_read_size   <= mem_axi_arsize;
                        mem_read_burst  <= mem_axi_arburst;
                        mem_read_addr = mem_axi_araddr & (ADDR_MASK << mem_axi_arsize);
                        mem_read_addr_wrap_lb = mem_axi_araddr & (ADDR_MASK << (mem_axi_arsize + $clog2(mem_axi_arlen)));
                        mem_read_addr_wrap_ub = mem_read_addr_wrap_lb + (2 ** mem_axi_arsize) * (mem_axi_arlen + 1);
                    end
                end
                STATE_R: begin
                    if (mem_axi_rready) begin
                        if (mem_axi_rlast) begin
                            mem_r_state <= STATE_AR;
                        end
                        if (mem_read_burst == BURST_WRAP && mem_read_addr == mem_read_addr_wrap_ub) begin
                            mem_read_addr = mem_read_addr_wrap_lb;
                        end
                        else begin
                            mem_read_addr = mem_read_addr + 2 ** mem_read_size;
                        end
                        mem_read_len <= mem_read_len - 1;
                    end
                end
            endcase
        end
        if (mem_r_state == STATE_AR && mem_axi_arvalid ||
            mem_r_state == STATE_R && mem_read_len != 0) begin
            result = $cosim_mem_read(mem_read_addr, temp_r_data);
            mem_axi_rdata_reg <= temp_r_data;
        end
    end

    assign mem_axi_arready    = mem_r_state == STATE_AR;
    assign mem_axi_rvalid     = mem_r_state == STATE_R;
    assign mem_axi_rdata      = mem_axi_rdata_reg;
    assign mem_axi_rid        = mem_read_id;
    assign mem_axi_rlast      = mem_read_len == 0;
    assign mem_axi_rresp      = RESP_OK;

    integer mem_w_state;

    reg [MEM_ID_WIDTH-1:0]      mem_write_id;
    reg [MEM_ADDR_WIDTH-1:0]    mem_write_addr;
    reg [7:0]                   mem_write_len;
    reg [2:0]                   mem_write_size;
    reg [1:0]                   mem_write_burst;
    reg [MEM_ADDR_WIDTH-1:0]    mem_write_addr_wrap_lb;
    reg [MEM_ADDR_WIDTH-1:0]    mem_write_addr_wrap_ub;

    reg [MEM_DATA_WIDTH-1:0]    temp_w_data;

    always @(posedge clk) begin
        if (rst) begin
            mem_w_state <= STATE_AW;
        end
        else begin
            case (mem_w_state)
                STATE_AW: begin
                    if (mem_axi_awvalid) begin
                        mem_w_state     <= STATE_W;
                        mem_write_id    <= mem_axi_awid;
                        mem_write_len   <= mem_axi_awlen;
                        mem_write_size  <= mem_axi_awsize;
                        mem_write_burst <= mem_axi_awburst;
                        mem_write_addr = mem_axi_awaddr & (ADDR_MASK << mem_axi_awsize);
                        mem_write_addr_wrap_lb = mem_axi_awaddr & (ADDR_MASK << (mem_axi_awsize + $clog2(mem_axi_awlen)));
                        mem_write_addr_wrap_ub = mem_write_addr_wrap_lb + (2 ** mem_axi_awsize) * (mem_axi_awlen + 1);
                    end
                end
                STATE_W: begin
                    if (mem_axi_wvalid) begin
                        if (mem_axi_wlast) begin
                            mem_w_state <= STATE_B;
                        end
                        result = $cosim_mem_read(mem_write_addr, temp_w_data);
                        for (i=0; i<MEM_STRB_WIDTH; i=i+1)
                            if (mem_axi_wstrb[i])
                                temp_w_data[i*8+:8] = mem_axi_wdata[i*8+:8];
                        result = $cosim_mem_write(mem_write_addr, temp_w_data);
                        if (mem_write_burst == BURST_WRAP && mem_write_addr == mem_write_addr_wrap_ub) begin
                            mem_write_addr = mem_write_addr_wrap_lb;
                        end
                        else begin
                            mem_write_addr = mem_write_addr + 2 ** mem_write_size;
                        end
                        mem_write_len <= mem_write_len - 1;
                    end
                end
                STATE_B: begin
                    if (mem_axi_bready) begin
                        mem_w_state <= STATE_AW;
                    end
                end
            endcase
        end
    end

    assign mem_axi_awready    = mem_w_state == STATE_AW;
    assign mem_axi_wready     = mem_w_state == STATE_W;
    assign mem_axi_bvalid     = mem_w_state == STATE_B;
    assign mem_axi_bid        = mem_write_id;
    assign mem_axi_bresp      = RESP_OK;

    // MMIO BFM

    integer mmio_state;

    integer     mmio_write;
    reg [31:0]  mmio_addr;
    reg [31:0]  mmio_value;

    always @(posedge clk) begin
        if (rst) begin
            mmio_state <= STATE_IDLE;
        end
        else begin
            case (mmio_state)
                STATE_IDLE: begin
                    result = $cosim_poll_req(mmio_write, mmio_addr, mmio_value);
                    if (result > 0) begin
                        mmio_state <= mmio_write ? STATE_AW : STATE_AR;
                    end
                end
                STATE_AR: begin
                    if (mmio_axi_arready) begin
                        mmio_state <= STATE_R;
                    end
                end
                STATE_R: begin
                    if (mmio_axi_rvalid) begin
                        result = $cosim_send_resp(0, mmio_axi_rdata);
                        mmio_state <= STATE_IDLE;
                    end
                end
                STATE_AW: begin
                    if (mmio_axi_awready) begin
                        mmio_state <= STATE_W;
                    end
                end
                STATE_W: begin
                    if (mmio_axi_wready) begin
                        mmio_state <= STATE_B;
                    end
                end
                STATE_B: begin
                    if (mmio_axi_bvalid) begin
                        result = $cosim_send_resp(1, 0);
                        mmio_state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

    assign mmio_axi_arvalid = mmio_state == STATE_AR;
    assign mmio_axi_araddr  = mmio_addr;
    assign mmio_axi_arprot  = 3'd0;

    assign mmio_axi_rready  = mmio_state == STATE_R;

    assign mmio_axi_awvalid = mmio_state == STATE_AW;
    assign mmio_axi_awaddr  = mmio_addr;
    assign mmio_axi_awprot  = 3'd0;

    assign mmio_axi_wvalid  = mmio_state == STATE_W;
    assign mmio_axi_wdata   = mmio_value;
    assign mmio_axi_wstrb   = 4'b1111;

    assign mmio_axi_bready  = mmio_state == STATE_B;

endmodule
