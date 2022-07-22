`timescale 1 ns / 1 ns

`include "loader.vh"

module sim_top();

    parameter CYCLE = 10;

    reg clk = 0, resetn = 0;
    always #(CYCLE/2) clk = ~clk;

    wire            m_axi_arvalid;
    wire            m_axi_arready;
    wire    [63:0]  m_axi_araddr;
    wire    [ 2:0]  m_axi_arprot;
    wire    [ 7:0]  m_axi_arlen;
    wire    [ 2:0]  m_axi_arsize;
    wire    [ 1:0]  m_axi_arburst;
    wire    [ 0:0]  m_axi_arlock;
    wire    [ 3:0]  m_axi_arcache;
    wire            m_axi_rvalid;
    wire            m_axi_rready;
    wire    [ 1:0]  m_axi_rresp;
    wire    [63:0]  m_axi_rdata;
    wire            m_axi_rlast;
    wire            m_axi_awvalid;
    wire            m_axi_awready;
    wire    [63:0]  m_axi_awaddr;
    wire    [ 2:0]  m_axi_awprot;
    wire    [ 7:0]  m_axi_awlen;
    wire    [ 2:0]  m_axi_awsize;
    wire    [ 1:0]  m_axi_awburst;
    wire    [ 0:0]  m_axi_awlock;
    wire    [ 3:0]  m_axi_awcache;
    wire            m_axi_wvalid;
    wire            m_axi_wready;
    wire    [63:0]  m_axi_wdata;
    wire    [ 7:0]  m_axi_wstrb;
    wire            m_axi_wlast;
    wire            m_axi_bvalid;
    wire            m_axi_bready;
    wire    [ 1:0]  m_axi_bresp;

    reg             s_axilite_arvalid = 0;
    wire            s_axilite_arready;
    reg     [11:0]  s_axilite_araddr = 0;
    wire            s_axilite_rvalid;
    wire    [31:0]  s_axilite_rdata;
    reg             s_axilite_awvalid = 0;
    wire            s_axilite_awready;
    reg     [11:0]  s_axilite_awaddr = 0;
    reg             s_axilite_wvalid = 0;
    wire            s_axilite_wready;
    reg     [31:0]  s_axilite_wdata = 0;
    wire            s_axilite_bvalid;

    wire emu_host_clk, emu_host_rst;
    wire emu_pause;
    wire emu_up_req, emu_down_req, emu_up_stat, emu_down_stat;
    wire emu_ff_se, emu_ram_se, emu_ram_sd;
    wire [63:0] emu_ff_di, emu_ff_do, emu_ram_di, emu_ram_do;
    wire emu_dut_ff_clk, emu_dut_ram_clk, emu_dut_rst, emu_dut_trig;

    wire trace_valid;
    wire [63:0] trace_data;
    reg trace_ready = 0;

    EMU_SYSTEM u_emu_system(
        .clk                        (clk),
        .resetn                     (resetn),

        .m_axi_arvalid              (m_axi_arvalid),
        .m_axi_arready              (m_axi_arready),
        .m_axi_araddr               (m_axi_araddr),
        .m_axi_arprot               (m_axi_arprot),
        .m_axi_arlen                (m_axi_arlen),
        .m_axi_arsize               (m_axi_arsize),
        .m_axi_arburst              (m_axi_arburst),
        .m_axi_arlock               (m_axi_arlock),
        .m_axi_arcache              (m_axi_arcache),
        .m_axi_rvalid               (m_axi_rvalid),
        .m_axi_rready               (m_axi_rready),
        .m_axi_rresp                (m_axi_rresp),
        .m_axi_rdata                (m_axi_rdata),
        .m_axi_rlast                (m_axi_rlast),
        .m_axi_awvalid              (m_axi_awvalid),
        .m_axi_awready              (m_axi_awready),
        .m_axi_awaddr               (m_axi_awaddr),
        .m_axi_awprot               (m_axi_awprot),
        .m_axi_awlen                (m_axi_awlen),
        .m_axi_awsize               (m_axi_awsize),
        .m_axi_awburst              (m_axi_awburst),
        .m_axi_awlock               (m_axi_awlock),
        .m_axi_awcache              (m_axi_awcache),
        .m_axi_wvalid               (m_axi_wvalid),
        .m_axi_wready               (m_axi_wready),
        .m_axi_wdata                (m_axi_wdata),
        .m_axi_wstrb                (m_axi_wstrb),
        .m_axi_wlast                (m_axi_wlast),
        .m_axi_bvalid               (m_axi_bvalid),
        .m_axi_bready               (m_axi_bready),
        .m_axi_bresp                (m_axi_bresp),

        .s_axilite_arvalid          (s_axilite_arvalid),
        .s_axilite_arready          (s_axilite_arready),
        .s_axilite_araddr           (s_axilite_araddr),
        .s_axilite_arprot           (3'd0),
        .s_axilite_rvalid           (s_axilite_rvalid),
        .s_axilite_rready           (1'b1),
        .s_axilite_rresp            (),
        .s_axilite_rdata            (s_axilite_rdata),
        .s_axilite_awvalid          (s_axilite_awvalid),
        .s_axilite_awready          (s_axilite_awready),
        .s_axilite_awaddr           (s_axilite_awaddr),
        .s_axilite_awprot           (3'd0),
        .s_axilite_wvalid           (s_axilite_wvalid),
        .s_axilite_wready           (s_axilite_wready),
        .s_axilite_wdata            (s_axilite_wdata),
        .s_axilite_wstrb            (4'b1111),
        .s_axilite_bvalid           (s_axilite_bvalid),
        .s_axilite_bready           (1'b1),
        .s_axilite_bresp            (),

        .u_trace_trace_valid        (trace_valid),
        .u_trace_trace_ready        (trace_ready),
        .u_trace_trace_data         (trace_data)
    );

    axi_ram #(
        .DATA_WIDTH     (64),
        .ADDR_WIDTH     (16),
        .ID_WIDTH       (1)
    )
    u_axi_ram(
        .clk            (clk),
        .rst            (!resetn),

        .s_axi_awid     (1'd0),
        .s_axi_awaddr   (m_axi_awaddr[15:0]),
        .s_axi_awlen    (m_axi_awlen),
        .s_axi_awsize   (m_axi_awsize),
        .s_axi_awburst  (m_axi_awburst),
        .s_axi_awlock   (m_axi_awlock),
        .s_axi_awcache  (m_axi_awcache),
        .s_axi_awprot   (m_axi_awprot),
        .s_axi_awvalid  (m_axi_awvalid),
        .s_axi_awready  (m_axi_awready),
        .s_axi_wdata    (m_axi_wdata),
        .s_axi_wstrb    (m_axi_wstrb),
        .s_axi_wlast    (m_axi_wlast),
        .s_axi_wvalid   (m_axi_wvalid),
        .s_axi_wready   (m_axi_wready),
        .s_axi_bid      (),
        .s_axi_bresp    (m_axi_bresp),
        .s_axi_bvalid   (m_axi_bvalid),
        .s_axi_bready   (m_axi_bready),
        .s_axi_arid     (1'd0),
        .s_axi_araddr   (m_axi_araddr[15:0]),
        .s_axi_arlen    (m_axi_arlen),
        .s_axi_arsize   (m_axi_arsize),
        .s_axi_arburst  (m_axi_arburst),
        .s_axi_arlock   (m_axi_arlock),
        .s_axi_arcache  (m_axi_arcache),
        .s_axi_arprot   (m_axi_arprot),
        .s_axi_arvalid  (m_axi_arvalid),
        .s_axi_arready  (m_axi_arready),
        .s_axi_rid      (),
        .s_axi_rdata    (m_axi_rdata),
        .s_axi_rresp    (m_axi_rresp),
        .s_axi_rlast    (m_axi_rlast),
        .s_axi_rvalid   (m_axi_rvalid),
        .s_axi_rready   (m_axi_rready)
    );

    reg [31:0] emucsr_rdata = 0;

    always @(posedge clk) begin
        if (s_axilite_arvalid && s_axilite_arready) begin
            //$display("EMUCSR RADDR %h", s_axilite_araddr);
            s_axilite_arvalid <= 1'b0;
        end
        if (s_axilite_rvalid) begin
            //$display("EMUCSR RDATA %h", s_axilite_rdata);
            emucsr_rdata = s_axilite_rdata;
        end
        if (s_axilite_awvalid && s_axilite_awready) begin
            //$display("EMUCSR WADDR %h", s_axilite_awaddr);
            s_axilite_awvalid <= 1'b0;
        end
        if (s_axilite_wvalid && s_axilite_wready) begin
            //$display("EMUCSR WDATA %h", s_axilite_wdata);
            s_axilite_wvalid <= 1'b0;
        end
    end

    /*
    always @(posedge clk) begin
        if (m_axi_arvalid && m_axi_arready) begin
            $display("AXIRAM AR ADDR=%h BURST=%h SIZE=%h LEN=%h", m_axi_araddr, m_axi_arburst, m_axi_arsize, m_axi_arlen);
        end
        if (m_axi_rvalid && m_axi_rready) begin
            $display("AXIRAM R DATA=%h LAST=%h RESP=%h", m_axi_rdata, m_axi_rlast, m_axi_rresp);
        end
        if (m_axi_awvalid && m_axi_awready) begin
            $display("AXIRAM AW ADDR=%h BURST=%h SIZE=%h LEN=%h", m_axi_awaddr, m_axi_awburst, m_axi_awsize, m_axi_awlen);
        end
        if (m_axi_wvalid && m_axi_wready) begin
            $display("AXIRAM W DATA=%h LAST=%h", m_axi_wdata, m_axi_wlast);
        end
        if (m_axi_bvalid && m_axi_bready) begin
            $display("AXIRAM B RESP=%h", m_axi_bresp);
        end
    end
    */

    `LOAD_DECLARE

    reg [31:0] cycle_lo_save = 0;
    integer i = 0;
    reg finish = 0;
    initial begin
        #(CYCLE*5);
        resetn = 1;

        #(CYCLE*100);

        $display("=== enable user triggers ===");
        s_axilite_awaddr = `EMU_TRIG_EN;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'hffffffff;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== set step count to 3 ===");
        s_axilite_awaddr = `EMU_STEP;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000003;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== start emulation & assert reset ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000002;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== wait for trigger ===");
        emucsr_rdata = 0;
        while ((emucsr_rdata & 1) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== deassert reset ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== read cycle_lo ===");
        s_axilite_araddr = `EMU_CYCLE_LO;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;
        $display("cycle_lo: %d", emucsr_rdata);

        $display("=== continue ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*100);

        $display("=== pause ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("success");
        $finish;
    end

    reg [63:0] trace_ref;

    always @(posedge clk) begin
        if (!resetn) begin
            trace_ref <= 0;
        end
        else if (trace_valid && trace_ready) begin
            trace_ref <= trace_ref + 1;
        end
    end

    always @(posedge clk) begin
        if (trace_valid && trace_ready) begin
            $display("trace_ref=%d, trace_data=%d", trace_ref, trace_data);
            if (trace_ref != trace_data) begin
                $display("ERROR: mismatch");
                $fatal;
            end
        end
        trace_ready <= $random;
    end

endmodule
