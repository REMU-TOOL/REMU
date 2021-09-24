`timescale 1 ns / 1 ns

module sim_top();

    parameter CYCLE = 10;

    reg clk = 0, rst = 1;

    always #(CYCLE/2) clk = ~clk;

    reg dut_reset = 1, emu_halt = 0;
    reg emu_scan_in_prep = 0, emu_scan_out_prep = 0;

    reg ren = 0, wen = 0;
    reg [4:0] raddr = 0, waddr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;

    reg s_tready = 0, m_tvalid = 0, m_tlast = 0;
    reg [63:0] m_tdata = 0;
    wire s_tvalid, s_tlast, m_tready;
    wire [63:0] s_tdata;

    mem u_mem ( 
        .clk                (clk),
        .rst                (dut_reset),
        .ren                (ren),
        .raddr              (raddr),
        .rdata              (rdata),
        .wen                (wen),
        .waddr              (waddr),
        .wdata              (wdata),
        .\$EMU$RESET        (rst),
        .\$EMU$HALT         (emu_halt),
        .\$EMU$RAM$RDATA    (s_tdata),
        .\$EMU$RAM$RID      (12'd0),
        .\$EMU$RAM$RLAST    (s_tlast),
        .\$EMU$RAM$RREADY   (s_tready),
        .\$EMU$RAM$RREQ     (emu_scan_out_prep),
        .\$EMU$RAM$RVALID   (s_tvalid),
        .\$EMU$RAM$WDATA    (m_tdata),
        .\$EMU$RAM$WID      (12'd0),
        .\$EMU$RAM$WLAST    (m_tlast),
        .\$EMU$RAM$WREADY   (m_tready),
        .\$EMU$RAM$WREQ     (emu_scan_in_prep),
        .\$EMU$RAM$WVALID   (m_tvalid)
    );

    reg [63:0] s_tdata_save = 0;
    always @(posedge clk) begin
        if (m_tvalid && m_tready) begin
            m_tvalid <= 0;
        end
        if (s_tvalid && s_tready) begin
            s_tdata_save = s_tdata;
            s_tready <= 0;
        end
    end

    integer i;

    reg [1023:0] data_a, data_b;

    initial begin
        #(CYCLE*5);
        rst = 0;
        #(CYCLE*5);
        dut_reset = 0;
        data_a = 'dx;
        data_b = 'dx;
        $display("write mem via user interface ...");
        wen = 1;
        for (i=0; i<32; i=i+1) begin
            wdata = $random;
            data_a[(31-i)*32+:32] = wdata;
            waddr = i;
            #CYCLE;
        end
        wen = 0;
        $display("read mem via accessor ...");
        emu_halt = 1;
        emu_scan_out_prep = 1;
        #CYCLE;
        emu_scan_out_prep = 0;
        #CYCLE;
        for (i=0; i<16; i=i+1) begin
            s_tready = 1;
            while (s_tready) #CYCLE;
            data_b[(15-i)*64+:64] = s_tdata_save;
        end
        #CYCLE;
        if (data_a != data_b) begin
            $display("data mismatch");
            $finish;
        end
        $display("ok");
        data_a = 'dx;
        data_b = 'dx;
        $display("write mem via accesor ...");
        emu_scan_in_prep = 1;
        #CYCLE;
        emu_scan_in_prep = 0;
        #CYCLE;
        for (i=0; i<16; i=i+1) begin
            m_tdata = {$random, $random};
            data_b[(15-i)*64+:64] = m_tdata;
            m_tlast = i == 15;
            m_tvalid = 1;
            while (m_tvalid) #CYCLE;
        end
        #(CYCLE*10); // workaround to wait for completion
        $display("read mem via user interface ...");
        emu_halt = 0;
        #CYCLE;
        ren = 1;
        for (i=0; i<32; i=i+1) begin
            raddr = i;
            #CYCLE;
            data_a[(31-i)*32+:32] = rdata;
        end
        ren = 0;
        #CYCLE;
        if (data_a != data_b) begin
            $display("data mismatch");
            $finish;
        end
        $display("ok");
        $finish;
    end

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("dump.vcd");
            $dumpvars();
        end
    end

endmodule
