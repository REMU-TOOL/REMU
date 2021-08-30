`timescale 1 ns / 1 ns

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

    reg             s_axilite_emureg_arvalid = 0;
    wire            s_axilite_emureg_arready;
    reg     [14:0]  s_axilite_emureg_araddr = 0;
    wire            s_axilite_emureg_rvalid;
    wire    [63:0]  s_axilite_emureg_rdata;
    reg             s_axilite_emureg_awvalid = 0;
    wire            s_axilite_emureg_awready;
    reg     [14:0]  s_axilite_emureg_awaddr = 0;
    reg             s_axilite_emureg_wvalid = 0;
    wire            s_axilite_emureg_wready;
    reg     [63:0]  s_axilite_emureg_wdata = 0;
    wire            s_axilite_emureg_bvalid;

    reg             s_axilite_idealmem_arvalid = 0;
    wire            s_axilite_idealmem_arready;
    reg     [11:0]  s_axilite_idealmem_araddr = 0;
    wire            s_axilite_idealmem_rvalid;
    wire    [31:0]  s_axilite_idealmem_rdata;
    reg             s_axilite_idealmem_awvalid = 0;
    wire            s_axilite_idealmem_awready;
    reg     [11:0]  s_axilite_idealmem_awaddr = 0;
    reg             s_axilite_idealmem_wvalid = 0;
    wire            s_axilite_idealmem_wready;
    reg     [31:0]  s_axilite_idealmem_wdata = 0;
    wire            s_axilite_idealmem_bvalid;

    emu_top u_emu_top(
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

        .s_axilite_emureg_arvalid   (s_axilite_emureg_arvalid),
        .s_axilite_emureg_arready   (s_axilite_emureg_arready),
        .s_axilite_emureg_araddr    (s_axilite_emureg_araddr),
        .s_axilite_emureg_arprot    (3'd0),
        .s_axilite_emureg_rvalid    (s_axilite_emureg_rvalid),
        .s_axilite_emureg_rready    (1'b1),
        .s_axilite_emureg_rresp     (),
        .s_axilite_emureg_rdata     (s_axilite_emureg_rdata),
        .s_axilite_emureg_awvalid   (s_axilite_emureg_awvalid),
        .s_axilite_emureg_awready   (s_axilite_emureg_awready),
        .s_axilite_emureg_awaddr    (s_axilite_emureg_awaddr),
        .s_axilite_emureg_awprot    (3'd0),
        .s_axilite_emureg_wvalid    (s_axilite_emureg_wvalid),
        .s_axilite_emureg_wready    (s_axilite_emureg_wready),
        .s_axilite_emureg_wdata     (s_axilite_emureg_wdata),
        .s_axilite_emureg_wstrb     (8'b11111111),
        .s_axilite_emureg_bvalid    (s_axilite_emureg_bvalid),
        .s_axilite_emureg_bready    (1'b1),
        .s_axilite_emureg_bresp     (),

        .s_axilite_idealmem_arvalid (s_axilite_idealmem_arvalid),
        .s_axilite_idealmem_arready (s_axilite_idealmem_arready),
        .s_axilite_idealmem_araddr  (s_axilite_idealmem_araddr),
        .s_axilite_idealmem_arprot  (3'd0),
        .s_axilite_idealmem_rvalid  (s_axilite_idealmem_rvalid),
        .s_axilite_idealmem_rready  (1'b1),
        .s_axilite_idealmem_rresp   (),
        .s_axilite_idealmem_rdata   (s_axilite_idealmem_rdata),
        .s_axilite_idealmem_awvalid (s_axilite_idealmem_awvalid),
        .s_axilite_idealmem_awready (s_axilite_idealmem_awready),
        .s_axilite_idealmem_awaddr  (s_axilite_idealmem_awaddr),
        .s_axilite_idealmem_awprot  (3'd0),
        .s_axilite_idealmem_wvalid  (s_axilite_idealmem_wvalid),
        .s_axilite_idealmem_wready  (s_axilite_idealmem_wready),
        .s_axilite_idealmem_wdata   (s_axilite_idealmem_wdata),
        .s_axilite_idealmem_wstrb   (4'b1111),
        .s_axilite_idealmem_bvalid  (s_axilite_idealmem_bvalid),
        .s_axilite_idealmem_bready  (1'b1),
        .s_axilite_idealmem_bresp   ()
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

    reg [31:0] emucsr_rdata = 0, idlmem_rdata = 0;
    reg [63:0] dutreg_rdata = 0;

    always @(posedge clk) begin
        if (s_axilite_arvalid && s_axilite_arready) begin
            $display("EMUCSR RADDR %h", s_axilite_araddr);
            s_axilite_arvalid <= 1'b0;
        end
        if (s_axilite_emureg_arvalid && s_axilite_emureg_arready) begin
            $display("DUTREG RADDR %h", s_axilite_emureg_araddr);
            s_axilite_emureg_arvalid <= 1'b0;
        end
        if (s_axilite_idealmem_arvalid && s_axilite_idealmem_arready) begin
            //$display("IDLMEM RADDR %h", s_axilite_idealmem_araddr);
            s_axilite_idealmem_arvalid <= 1'b0;
        end
        if (s_axilite_rvalid) begin
            $display("EMUCSR RDATA %h", s_axilite_rdata);
            emucsr_rdata = s_axilite_rdata;
        end
        if (s_axilite_emureg_rvalid) begin
            $display("DUTREG RDATA %h", s_axilite_emureg_rdata);
            dutreg_rdata = s_axilite_emureg_rdata;
        end
        if (s_axilite_idealmem_rvalid) begin
            //$display("IDLMEM RDATA %h", s_axilite_idealmem_rdata);
            idlmem_rdata = s_axilite_idealmem_rdata;
        end
        if (s_axilite_awvalid && s_axilite_awready) begin
            $display("EMUCSR WADDR %h", s_axilite_awaddr);
            s_axilite_awvalid <= 1'b0;
        end
        if (s_axilite_emureg_awvalid && s_axilite_emureg_awready) begin
            $display("DUTREG WADDR %h", s_axilite_emureg_awaddr);
            s_axilite_emureg_awvalid <= 1'b0;
        end
        if (s_axilite_idealmem_awvalid && s_axilite_idealmem_awready) begin
            //$display("IDLMEM WADDR %h", s_axilite_idealmem_awaddr);
            s_axilite_idealmem_awvalid <= 1'b0;
        end
        if (s_axilite_wvalid && s_axilite_wready) begin
            $display("EMUCSR WDATA %h", s_axilite_wdata);
            s_axilite_wvalid <= 1'b0;
        end
        if (s_axilite_emureg_wvalid && s_axilite_emureg_wready) begin
            $display("DUTREG WDATA %h", s_axilite_emureg_wdata);
            s_axilite_emureg_wvalid <= 1'b0;
        end
        if (s_axilite_idealmem_wvalid && s_axilite_idealmem_wready) begin
            //$display("IDLMEM WDATA %h", s_axilite_idealmem_wdata);
            s_axilite_idealmem_wvalid <= 1'b0;
        end
    end

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

    reg [31:0] cycle_lo_save = 0, pc_save = 0;
    reg [31:0] idealmem_save [1023:0];
    integer i = 0;
    reg finish = 0;
    initial begin
        #(CYCLE*5);
        resetn = 1;
        #(CYCLE*100);

        $display("=== halt & prepare for dump ===");
        // W EMUCSR[0x0] 0x9
        s_axilite_awaddr = 12'h000;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000009;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // R EMUCSR[0x0]
        s_axilite_araddr = 12'h000;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*5);

        $display("=== read cycle_lo ===");
        // R EMUCSR[0x8]
        s_axilite_araddr = 12'h008;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;
        $display("cycle_lo: %d", emucsr_rdata);
        cycle_lo_save = emucsr_rdata;

        #(CYCLE*5);

        $display("=== read dut register ===");
        // R DUTREG[0x0]
        s_axilite_emureg_araddr = 0;
        s_axilite_emureg_arvalid = 1;
        while (!s_axilite_emureg_rvalid) #CYCLE;
        #CYCLE;
        pc_save = dutreg_rdata;

        #(CYCLE*5);

        $display("=== read ideal mem ===");
        for (i=0; i<1024; i=i+1) begin
            // R IDLMEM[i]
            s_axilite_idealmem_araddr = i*4;
            s_axilite_idealmem_arvalid = 1;
            while (!s_axilite_idealmem_rvalid) #CYCLE;
            #CYCLE;
            idealmem_save[i] = idlmem_rdata;
        end

        #(CYCLE*5);

        $display("=== start dma_wr transfer ===");
        // W EMUCSR[0x20] 0x0
        s_axilite_awaddr = 12'h020;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x24] 0x0
        s_axilite_awaddr = 12'h024;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x28] 0x80
        s_axilite_awaddr = 12'h028;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000080;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x2c] 0x1
        s_axilite_awaddr = 12'h02c;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 1;
        while (emucsr_rdata & 1) begin
            #(CYCLE*10);
            // R EMUCSR[0x2c]
            s_axilite_araddr = 12'h02c;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        #(CYCLE*5);

        $display("=== continue ===");
        // W EMUCSR[0x0] 0x0
        s_axilite_awaddr = 12'h000;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        while (!finish) #CYCLE;

        $display("=== halt & prepare for load ===");
        // W EMUCSR[0x0] 0x5
        s_axilite_awaddr = 12'h000;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000005;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // R EMUCSR[0x0]
        s_axilite_araddr = 12'h000;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*5);

        $display("=== read cycle_lo ===");
        // R EMUCSR[0x8]
        s_axilite_araddr = 12'h008;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;
        $display("cycle_lo: %d", emucsr_rdata);

        #(CYCLE*5);

        $display("=== restore cycle_lo ===");
        // W EMUCSR[0x8]
        s_axilite_awaddr = 12'h008;
        s_axilite_awvalid = 1;
        s_axilite_wdata = cycle_lo_save;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*5);

        $display("=== restore dut register ===");
        // W DUTREG[0x0]
        s_axilite_emureg_awaddr = 0;
        s_axilite_emureg_awvalid = 1;
        s_axilite_emureg_wdata = pc_save;
        s_axilite_emureg_wvalid = 1;
        while (!s_axilite_emureg_bvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*5);

        $display("=== restore ideal mem ===");
        for (i=0; i<1024; i=i+1) begin
            // W IDLMEM[i]
            s_axilite_idealmem_awaddr = i*4;
            s_axilite_idealmem_awvalid = 1;
            s_axilite_idealmem_wdata = idealmem_save[i];
            s_axilite_idealmem_wvalid = 1;
            while (!s_axilite_idealmem_bvalid) #CYCLE;
            #CYCLE;
        end

        #(CYCLE*5);

        $display("=== start dma_rd transfer ===");
        // W EMUCSR[0x10] 0x0
        s_axilite_awaddr = 12'h010;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x14] 0x0
        s_axilite_awaddr = 12'h014;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x18] 0x80
        s_axilite_awaddr = 12'h018;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000080;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // W EMUCSR[0x1c] 0x1
        s_axilite_awaddr = 12'h01c;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        emucsr_rdata = 1;
        while (emucsr_rdata & 1) begin
            #(CYCLE*10);
            // R EMUCSR[0x1c]
            s_axilite_araddr = 12'h01c;
            s_axilite_arvalid = 1;
            while (!s_axilite_rvalid) #CYCLE;
            #CYCLE;
        end

        #(CYCLE*5);

        finish = 0;

        $display("=== continue ===");
        // W EMUCSR[0x0] 0x0
        s_axilite_awaddr = 12'h000;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000000;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;

        while (!finish) #CYCLE;

        #(CYCLE*5);

        $display("=== halt ===");
        // W EMUCSR[0x0] 0x1
        s_axilite_awaddr = 12'h000;
        s_axilite_awvalid = 1;
        s_axilite_wdata = 32'h00000001;
        s_axilite_wvalid = 1;
        while (!s_axilite_bvalid) #CYCLE;
        #CYCLE;
        // R EMUCSR[0x0]
        s_axilite_araddr = 12'h000;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;

        #(CYCLE*5);

        $display("=== read cycle_lo ===");
        // R EMUCSR[0x8]
        s_axilite_araddr = 12'h008;
        s_axilite_arvalid = 1;
        while (!s_axilite_rvalid) #CYCLE;
        #CYCLE;
        $display("cycle_lo: %d", emucsr_rdata);

        #(CYCLE*5);

        $finish;
    end

    reg [31:0] result;
    always #CYCLE begin
        result = u_emu_top.u_mem.mem[3];
        if (result != 32'hffffffff && !finish) begin
            $display("[%dns] Benchmark finished with result = %d", $time, result);
            finish = 1;
        end
    end

    initial $readmemh("initmem.txt", u_emu_top.u_mem.mem);

    initial begin
        $dumpfile("output/dump.vcd");
        $dumpvars();
    end

endmodule
