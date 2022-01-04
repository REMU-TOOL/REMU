`timescale 1 ns / 1 ns

`include "test.vh"
`include "emu_csr.vh"

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

    wire              mem_axi_awvalid;
	wire              mem_axi_awready;
	wire       [31:0] mem_axi_awaddr;

	wire              mem_axi_wvalid;
	wire              mem_axi_wready;
	wire       [31:0] mem_axi_wdata;
	wire       [ 3:0] mem_axi_wstrb;

	wire              mem_axi_bvalid;
	wire              mem_axi_bready;

	wire              mem_axi_arvalid;
	wire              mem_axi_arready;
	wire       [31:0] mem_axi_araddr;

	wire              mem_axi_rvalid;
	wire              mem_axi_rready;
	wire       [31:0] mem_axi_rdata;

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

        .emu_auto_0_dram_awvalid        (mem_axi_awvalid),
        .emu_auto_0_dram_awready        (mem_axi_awready),
        .emu_auto_0_dram_awaddr         (mem_axi_awaddr),
        .emu_auto_0_dram_awid           (),
        .emu_auto_0_dram_awlen          (),
        .emu_auto_0_dram_awsize         (),
        .emu_auto_0_dram_awburst        (),
        .emu_auto_0_dram_awlock         (),
        .emu_auto_0_dram_awcache        (),
        .emu_auto_0_dram_awprot         (),
        .emu_auto_0_dram_awqos          (),
        .emu_auto_0_dram_awregion       (),
        .emu_auto_0_dram_wvalid         (mem_axi_wvalid),
        .emu_auto_0_dram_wready         (mem_axi_wready),
        .emu_auto_0_dram_wdata          (mem_axi_wdata),
        .emu_auto_0_dram_wstrb          (mem_axi_wstrb),
        .emu_auto_0_dram_wlast          (),
        .emu_auto_0_dram_bvalid         (mem_axi_bvalid),
        .emu_auto_0_dram_bready         (mem_axi_bready),
        .emu_auto_0_dram_bresp          (2'b00),
        .emu_auto_0_dram_bid            (1'd0),
        .emu_auto_0_dram_arvalid        (mem_axi_arvalid),
        .emu_auto_0_dram_arready        (mem_axi_arready),
        .emu_auto_0_dram_araddr         (mem_axi_araddr),
        .emu_auto_0_dram_arid           (),
        .emu_auto_0_dram_arlen          (),
        .emu_auto_0_dram_arsize         (),
        .emu_auto_0_dram_arburst        (),
        .emu_auto_0_dram_arlock         (),
        .emu_auto_0_dram_arcache        (),
        .emu_auto_0_dram_arprot         (),
        .emu_auto_0_dram_arqos          (),
        .emu_auto_0_dram_arregion       (),
        .emu_auto_0_dram_rvalid         (mem_axi_rvalid),
        .emu_auto_0_dram_rready         (mem_axi_rready),
        .emu_auto_0_dram_rdata          (mem_axi_rdata),
        .emu_auto_0_dram_rresp          (2'b00),
        .emu_auto_0_dram_rid            (1'd0),
        .emu_auto_0_dram_rlast          (1'b1)
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

    sim_dram u_sim_dram (
        .clk            (clk),
        .rst            (!resetn),
        .mem_axi_awvalid    (mem_axi_awvalid),
        .mem_axi_awready    (mem_axi_awready),
        .mem_axi_awaddr     (mem_axi_awaddr),
        .mem_axi_wvalid     (mem_axi_wvalid),
        .mem_axi_wready     (mem_axi_wready),
        .mem_axi_wdata      (mem_axi_wdata),
        .mem_axi_wstrb      (mem_axi_wstrb),
        .mem_axi_bvalid     (mem_axi_bvalid),
        .mem_axi_bready     (mem_axi_bready),
        .mem_axi_arvalid    (mem_axi_arvalid),
        .mem_axi_arready    (mem_axi_arready),
        .mem_axi_araddr     (mem_axi_araddr),
        .mem_axi_rvalid     (mem_axi_rvalid),
        .mem_axi_rready     (mem_axi_rready),
        .mem_axi_rdata      (mem_axi_rdata)
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

    reg [31:0] cycle_lo_save = 0;
    reg [7:0] mem_save [0:64*1024-1];
    integer i = 0;
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
            s_axilite_araddr = `EMU_PUTCHAR;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
            if ((emucsr_rdata & 32'h80000000) != 0)
                $write("%c", emucsr_rdata & 8'hff);
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

        $display("=== set step count to 16384 ===");
        s_axilite_awaddr = `EMU_STEP;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00004000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== continue ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== wait for trigger ===");
        emucsr_rdata = 0;
        while ((emucsr_rdata & 1) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_PUTCHAR;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
            if ((emucsr_rdata & 32'h80000000) != 0)
                $write("%c", emucsr_rdata & 8'hff);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== pause ===");
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
        cycle_lo_save = emucsr_rdata;

        $display("=== save dram data ===");
        for (i=0; i<65536; i=i+1)
            mem_save[i] = u_sim_dram.mem[i];

        $display("=== start dma transfer ===");
        s_axilite_awaddr = `EMU_DMA_ADDR_LO;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        s_axilite_awaddr = `EMU_DMA_ADDR_HI;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        s_axilite_awaddr = `EMU_DMA_CTRL;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 1;
        while (emucsr_rdata & 1) begin
            #(CYCLE*100);
            s_axilite_araddr = `EMU_DMA_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== continue ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== wait for trigger ===");
        emucsr_rdata = 0;
        while ((emucsr_rdata & 1) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_PUTCHAR;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
            if ((emucsr_rdata & 32'h80000000) != 0)
                $write("%c", emucsr_rdata & 8'hff);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== pause ===");
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

        $display("=== restore cycle_lo ===");
        s_axilite_awaddr = `EMU_CYCLE_LO;
        s_axilite_awvalid = 1;
        s_axilite_wdata = cycle_lo_save;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== restore dram data ===");
        for (i=0; i<65536; i=i+1)
            u_sim_dram.mem[i] = mem_save[i];

        $display("=== start dma transfer ===");
        s_axilite_awaddr = `EMU_DMA_ADDR_LO;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        s_axilite_awaddr = `EMU_DMA_ADDR_HI;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        s_axilite_awaddr = `EMU_DMA_CTRL;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000003;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 1;
        while (emucsr_rdata & 1) begin
            #(CYCLE*100);
            s_axilite_araddr = `EMU_DMA_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== continue ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== wait for trigger ===");
        emucsr_rdata = 0;
        while ((emucsr_rdata & 1) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_PUTCHAR;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
            if ((emucsr_rdata & 32'h80000000) != 0)
                $write("%c", emucsr_rdata & 8'hff);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        $display("=== read emu_stat ===");
        s_axilite_araddr = `EMU_STAT;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;

        $display("=== read cycle_lo ===");
        s_axilite_araddr = `EMU_CYCLE_LO;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;
        $display("cycle_lo: %d", emucsr_rdata);

        $display("success");
        $finish;
    end

    initial $readmemh("../../design/picorv32/baremetal.hex", u_sim_dram.mem);

    `DUMP_VCD

endmodule

module sim_dram (
    input   clk,
    input   rst,

    input             mem_axi_awvalid,
	output            mem_axi_awready,
	input      [31:0] mem_axi_awaddr,

	input             mem_axi_wvalid,
	output            mem_axi_wready,
	input      [31:0] mem_axi_wdata,
	input      [ 3:0] mem_axi_wstrb,

	output            mem_axi_bvalid,
	input             mem_axi_bready,

	input             mem_axi_arvalid,
	output            mem_axi_arready,
	input      [31:0] mem_axi_araddr,

	output            mem_axi_rvalid,
	input             mem_axi_rready,
	output     [31:0] mem_axi_rdata
);

    reg [7:0] mem [0:64*1024-1];

    reg [31:0] reg_write_addr;
    reg [31:0] reg_write_data;
    reg [3:0] reg_write_strb;
    reg reg_write_addr_valid, reg_write_data_valid, reg_write_resp_valid;
    wire reg_write_addr_data_ok = reg_write_addr_valid && reg_write_data_valid;

    always @(posedge clk) begin
        if (rst) begin
            reg_write_addr          <= 12'd0;
            reg_write_data          <= 32'd0;
            reg_write_strb          <= 4'd0;
            reg_write_addr_valid    <= 1'b0;
            reg_write_data_valid    <= 1'b0;
            reg_write_resp_valid    <= 1'b0;
        end
        else begin
            if (mem_axi_awvalid && mem_axi_awready) begin
                reg_write_addr          <= mem_axi_awaddr;
                reg_write_addr_valid    <= 1'b1;
            end
            if (mem_axi_wvalid && mem_axi_wready) begin
                reg_write_data          <= mem_axi_wdata;
                reg_write_strb          <= mem_axi_wstrb;
                reg_write_data_valid    <= 1'b1;
            end
            if (reg_write_addr_data_ok) begin
                reg_write_addr_valid    <= 1'b0;
                reg_write_data_valid    <= 1'b0;
                reg_write_resp_valid    <= 1'b1;
            end
            if (mem_axi_bvalid && mem_axi_bready) begin
                reg_write_resp_valid    <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (reg_write_addr_data_ok) begin
            if (reg_write_strb[0]) mem[reg_write_addr + 0] <= reg_write_data[ 7: 0];
            if (reg_write_strb[1]) mem[reg_write_addr + 1] <= reg_write_data[15: 8];
            if (reg_write_strb[2]) mem[reg_write_addr + 2] <= reg_write_data[23:16];
            if (reg_write_strb[3]) mem[reg_write_addr + 3] <= reg_write_data[31:24];
        end
    end

    assign mem_axi_awready    = !reg_write_addr_valid && !reg_write_resp_valid;
    assign mem_axi_wready     = !reg_write_data_valid;
    assign mem_axi_bvalid     = reg_write_resp_valid;

    reg [31:0] reg_read_addr;
    reg [31:0] reg_read_data;
    reg reg_read_addr_valid, reg_read_data_valid;
    wire reg_do_read = reg_read_addr_valid && !reg_read_data_valid;

    always @(posedge clk) begin
        if (rst) begin
            reg_read_addr       <= 12'd0;
            reg_read_data       <= 32'd0;
            reg_read_addr_valid <= 1'b0;
            reg_read_data_valid <= 1'b0;
        end
        else begin
            if (mem_axi_arvalid && mem_axi_arready) begin
                reg_read_addr       <= mem_axi_araddr;
                reg_read_addr_valid <= 1'b1;
            end
            if (reg_do_read) begin
                reg_read_data[ 7: 0] <= mem[reg_read_addr + 0];
                reg_read_data[15: 8] <= mem[reg_read_addr + 1];
                reg_read_data[23:16] <= mem[reg_read_addr + 2];
                reg_read_data[31:24] <= mem[reg_read_addr + 3];
                reg_read_data_valid <= 1'b1;
            end
            if (mem_axi_rvalid && mem_axi_rready) begin
                reg_read_addr_valid <= 1'b0;
                reg_read_data_valid <= 1'b0;
            end
        end
    end

    assign mem_axi_arready    = !reg_read_addr_valid;
    assign mem_axi_rvalid     = reg_read_data_valid;
    assign mem_axi_rdata      = reg_read_data;

endmodule
