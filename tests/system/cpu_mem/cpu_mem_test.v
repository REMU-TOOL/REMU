`timescale 1 ns / 1 ns

`include "loader.vh"
`include "emu_csr.vh"

`include "axi.vh"

module sim_top();

    parameter CYCLE = 10;

    reg clk = 0, resetn = 0;
    always #(CYCLE/2) clk = ~clk;

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

    `AXI4_WIRE          (m_axi, 64, 64, 1);
    `AXI4_WIRE          (mem_axi, 32, 32, 1);
    `AXI4_WIRE_NO_ID    (lsu_axi, 32, 32);

    EMU_SYSTEM u_emu_system(
        .clk                        (clk),
        .resetn                     (resetn),

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

        `AXI4_CONNECT               (m_axi, m_axi),
        `AXI4_CONNECT               (uncore_u_rammodel_host_axi, mem_axi),
        `AXI4_CONNECT_NO_ID         (uncore_u_rammodel_lsu_axi, lsu_axi)
    );

    assign mem_axi_bresp = 2'b00;
    assign mem_axi_bid = 1'd0;
    assign mem_axi_rresp = 2'b00;
    assign mem_axi_rid = 1'd0;
    assign mem_axi_rlast = 1'd1;

    axi_ram #(
        .DATA_WIDTH     (64),
        .ADDR_WIDTH     (16),
        .ID_WIDTH       (1)
    )
    u_axi_ram(
        .clk            (clk),
        .rst            (!resetn),

        .s_axi_awid     (m_axi_awid),
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
        .s_axi_bid      (m_axi_bid),
        .s_axi_bresp    (m_axi_bresp),
        .s_axi_bvalid   (m_axi_bvalid),
        .s_axi_bready   (m_axi_bready),
        .s_axi_arid     (m_axi_arid),
        .s_axi_araddr   (m_axi_araddr[15:0]),
        .s_axi_arlen    (m_axi_arlen),
        .s_axi_arsize   (m_axi_arsize),
        .s_axi_arburst  (m_axi_arburst),
        .s_axi_arlock   (m_axi_arlock),
        .s_axi_arcache  (m_axi_arcache),
        .s_axi_arprot   (m_axi_arprot),
        .s_axi_arvalid  (m_axi_arvalid),
        .s_axi_arready  (m_axi_arready),
        .s_axi_rid      (m_axi_rid),
        .s_axi_rdata    (m_axi_rdata),
        .s_axi_rresp    (m_axi_rresp),
        .s_axi_rlast    (m_axi_rlast),
        .s_axi_rvalid   (m_axi_rvalid),
        .s_axi_rready   (m_axi_rready)
    );

    axi_ram #(
        .DATA_WIDTH     (64),
        .ADDR_WIDTH     (16),
        .ID_WIDTH       (1)
    )
    u_axi_lsu_ram(
        .clk            (clk),
        .rst            (!resetn),

        .s_axi_awid     (1'd0),
        .s_axi_awaddr   (lsu_axi_awaddr[15:0]),
        .s_axi_awlen    (lsu_axi_awlen),
        .s_axi_awsize   (lsu_axi_awsize),
        .s_axi_awburst  (lsu_axi_awburst),
        .s_axi_awlock   (lsu_axi_awlock),
        .s_axi_awcache  (lsu_axi_awcache),
        .s_axi_awprot   (lsu_axi_awprot),
        .s_axi_awvalid  (lsu_axi_awvalid),
        .s_axi_awready  (lsu_axi_awready),
        .s_axi_wdata    (lsu_axi_wdata),
        .s_axi_wstrb    (lsu_axi_wstrb),
        .s_axi_wlast    (lsu_axi_wlast),
        .s_axi_wvalid   (lsu_axi_wvalid),
        .s_axi_wready   (lsu_axi_wready),
        .s_axi_bid      (),
        .s_axi_bresp    (lsu_axi_bresp),
        .s_axi_bvalid   (lsu_axi_bvalid),
        .s_axi_bready   (lsu_axi_bready),
        .s_axi_arid     (1'd0),
        .s_axi_araddr   (lsu_axi_araddr[15:0]),
        .s_axi_arlen    (lsu_axi_arlen),
        .s_axi_arsize   (lsu_axi_arsize),
        .s_axi_arburst  (lsu_axi_arburst),
        .s_axi_arlock   (lsu_axi_arlock),
        .s_axi_arcache  (lsu_axi_arcache),
        .s_axi_arprot   (lsu_axi_arprot),
        .s_axi_arvalid  (lsu_axi_arvalid),
        .s_axi_arready  (lsu_axi_arready),
        .s_axi_rid      (),
        .s_axi_rdata    (lsu_axi_rdata),
        .s_axi_rresp    (lsu_axi_rresp),
        .s_axi_rlast    (lsu_axi_rlast),
        .s_axi_rvalid   (lsu_axi_rvalid),
        .s_axi_rready   (lsu_axi_rready)
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

        $display("=== set step count to 10 ===");
        s_axilite_awaddr = `EMU_STEP;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h0000000a;
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

        $display("=== down ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000009;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 0;
        while ((emucsr_rdata & (1 << 5)) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

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

        $display("=== up ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000005;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 0;
        while ((emucsr_rdata & (1 << 4)) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
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

        $display("=== restore cycle_lo ===");
        s_axilite_awaddr = `EMU_CYCLE_LO;
        s_axilite_awvalid = 1;
        s_axilite_wdata = cycle_lo_save;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        $display("=== down ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000009;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 0;
        while ((emucsr_rdata & (1 << 5)) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
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

        $display("=== up ===");
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000005;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 0;
        while ((emucsr_rdata & (1 << 4)) == 0) begin
            #(CYCLE*20);
            s_axilite_araddr = `EMU_STAT;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end
        s_axilite_awaddr = `EMU_STAT;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
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

    initial $readmemh("../../../design/picorv32/baremetal.hex", u_sim_dram.mem);

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
