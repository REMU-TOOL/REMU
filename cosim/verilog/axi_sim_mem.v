`timescale 1ns / 1ps

module axi_sim_mem #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   STRB_WIDTH      = DATA_WIDTH / 8,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000,
    parameter   MEM_INIT        = 0
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,
    output wire [ID_WIDTH-1:0]    s_axi_bid,
    output wire [1:0]             s_axi_bresp,
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,
    output wire [ID_WIDTH-1:0]    s_axi_rid,
    output wire [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rlast,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready
);

    initial begin
        if (ADDR_WIDTH < 1 || ADDR_WIDTH > 64) begin
            $display("%m: ADDR_WIDTH must be in [1,64]");
            $finish;
        end
        if (DATA_WIDTH != 8 && DATA_WIDTH != 16 && DATA_WIDTH != 32 && DATA_WIDTH != 64) begin
            $display("%m: DATA_WIDTH must be 8, 16, 32 or 64");
            $finish;
        end
        if (ID_WIDTH < 1) begin
            $display("%m: ID_WIDTH must be greater than 0");
            $finish;
        end
        if (MEM_SIZE % 'h1000 != 0) begin
            $display("%m: MEM_SIZE must be aligned to 4KB");
            $finish;
        end
    end

    localparam MEM_WORDS    = MEM_SIZE / STRB_WIDTH;
    localparam ADDR_MASK    = {ADDR_WIDTH{1'b1}};

    reg [DATA_WIDTH-1:0] mem_data [MEM_WORDS-1:0];

    integer i;

    initial begin
        if (MEM_INIT)
            for (i=0; i<MEM_WORDS; i=i+1)
                mem_data[i] = 0;
    end

    localparam BURST_INCR   = 2'b01;
    localparam BURST_WRAP   = 2'b10;

    localparam RESP_OK      = 2'b00;
    localparam RESP_SLVERR  = 2'b10;

    localparam R_STATE_AR   = 0;
    localparam R_STATE_R    = 1;

    integer r_state;

    reg [ID_WIDTH-1:0]      read_id;
    reg [ADDR_WIDTH-1:0]    read_addr;
    reg [7:0]               read_len;
    reg [2:0]               read_size;
    reg [1:0]               read_burst;
    reg [ADDR_WIDTH-1:0]    read_addr_wrap_lb;
    reg [ADDR_WIDTH-1:0]    read_addr_wrap_ub;

    always @(posedge clk) begin
        if (rst) begin
            r_state <= R_STATE_AR;
        end
        else begin
            case (r_state)
                R_STATE_AR: begin
                    if (s_axi_arvalid) begin
                        r_state     <= R_STATE_R;
                        read_id     <= s_axi_arid;
                        read_addr   <= s_axi_araddr & (ADDR_MASK << s_axi_arsize);
                        read_len    <= s_axi_arlen;
                        read_size   <= s_axi_arsize;
                        read_burst  <= s_axi_arburst;
                        read_addr_wrap_lb = s_axi_araddr & (ADDR_MASK << (s_axi_arsize + $clog2(s_axi_arlen)));
                        read_addr_wrap_ub = read_addr_wrap_lb + (2 ** s_axi_arsize) * (s_axi_arlen + 1);
                    end
                end
                R_STATE_R: begin
                    if (s_axi_rready) begin
                        if (s_axi_rlast) begin
                            r_state <= R_STATE_AR;
                        end
                        if (read_burst == BURST_WRAP && read_addr == read_addr_wrap_ub) begin
                            read_addr <= read_addr_wrap_lb;
                        end
                        else begin
                            read_addr <= read_addr + 2 ** read_size;
                        end
                        read_len <= read_len - 1;
                    end
                end
            endcase
        end
    end

    assign s_axi_arready    = r_state == R_STATE_AR;
    assign s_axi_rvalid     = r_state == R_STATE_R;
    assign s_axi_rid        = read_id;
    assign s_axi_rdata      = mem_data[read_addr/STRB_WIDTH];
    assign s_axi_rlast      = read_len == 0;
    assign s_axi_rresp      = RESP_OK;

    localparam W_STATE_AW   = 0;
    localparam W_STATE_W    = 1;
    localparam W_STATE_B    = 2;

    integer w_state;

    reg [ID_WIDTH-1:0]      write_id;
    reg [ADDR_WIDTH-1:0]    write_addr;
    reg [7:0]               write_len;
    reg [2:0]               write_size;
    reg [1:0]               write_burst;
    reg [ADDR_WIDTH-1:0]    write_addr_wrap_lb;
    reg [ADDR_WIDTH-1:0]    write_addr_wrap_ub;

    always @(posedge clk) begin
        if (rst) begin
            w_state <= W_STATE_AW;
        end
        else begin
            case (w_state)
                W_STATE_AW: begin
                    if (s_axi_awvalid) begin
                        w_state     <= W_STATE_W;
                        write_id    <= s_axi_awid;
                        write_addr  <= s_axi_awaddr & (ADDR_MASK << s_axi_awsize);
                        write_len   <= s_axi_awlen;
                        write_size  <= s_axi_awsize;
                        write_burst <= s_axi_awburst;
                        write_addr_wrap_lb = s_axi_awaddr & (ADDR_MASK << (s_axi_awsize + $clog2(s_axi_awlen)));
                        write_addr_wrap_ub = write_addr_wrap_lb + (2 ** s_axi_awsize) * (s_axi_awlen + 1);
                    end
                end
                W_STATE_W: begin
                    if (s_axi_wvalid) begin
                        if (s_axi_wlast) begin
                            w_state <= W_STATE_B;
                        end
                        for (i=0; i<STRB_WIDTH; i=i+1)
                            if (s_axi_wstrb[i])
                                mem_data[write_addr/STRB_WIDTH][i*8+:8] <= s_axi_wdata[i*8+:8];
                        if (write_burst == BURST_WRAP && write_addr == write_addr_wrap_ub) begin
                            write_addr <= write_addr_wrap_lb;
                        end
                        else begin
                            write_addr <= write_addr + 2 ** write_size;
                        end
                        write_len <= write_len - 1;
                    end
                end
                W_STATE_B: begin
                    if (s_axi_bready) begin
                        w_state <= W_STATE_AW;
                    end
                end
            endcase
        end
    end

    assign s_axi_awready    = w_state == W_STATE_AW;
    assign s_axi_wready     = w_state == W_STATE_W;
    assign s_axi_bvalid     = w_state == W_STATE_B;
    assign s_axi_bid        = write_id;
    assign s_axi_bresp      = RESP_OK;

endmodule
