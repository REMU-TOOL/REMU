`timescale 1ns / 1ps

`ifdef EMULIB_AXIS_WIDTH_UPSIZER_TB

module `EMULIB_AXIS_WIDTH_UPSIZER_TB;

    localparam S_TDATA_BYTES    = 2;
    localparam M_TDATA_BYTES    = 10;
    localparam BYTE_WIDTH       = 8;

    localparam S_TDATA_WIDTH = S_TDATA_BYTES * BYTE_WIDTH;
    localparam M_TDATA_WIDTH = M_TDATA_BYTES * BYTE_WIDTH;

    reg clk = 0, rst = 1;
    reg                         s_tvalid = 1'b0;
    wire                        s_tready;
    reg  [S_TDATA_WIDTH-1:0]    s_tdata;
    reg  [S_TDATA_BYTES-1:0]    s_tkeep;
    reg                         s_tlast;
    wire                        m_tvalid;
    reg                         m_tready = 1'b0;
    wire [M_TDATA_WIDTH-1:0]    m_tdata;
    wire [M_TDATA_BYTES-1:0]    m_tkeep;
    wire                        m_tlast;

    always #5 clk = ~clk;

    emulib_axis_width_upsizer #(
        .S_TDATA_BYTES  (S_TDATA_BYTES),
        .M_TDATA_BYTES  (M_TDATA_BYTES),
        .BYTE_WIDTH     (BYTE_WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .s_tvalid   (s_tvalid),
        .s_tready   (s_tready),
        .s_tdata    (s_tdata),
        .s_tkeep    (s_tkeep),
        .s_tlast    (s_tlast),
        .m_tvalid   (m_tvalid),
        .m_tready   (m_tready),
        .m_tdata    (m_tdata),
        .m_tkeep    (m_tkeep),
        .m_tlast    (m_tlast)
    );

    task s_req (
        input [S_TDATA_WIDTH-1:0] tdata,
        input [S_TDATA_BYTES-1:0] tkeep,
        input tlast
    );
    integer delay;
    begin
        delay = $random % 20;
        while (delay > 0) @(posedge clk) delay = delay - 1;
        s_tdata = tdata;
        s_tkeep = tkeep;
        s_tlast = tlast;
        s_tvalid = 1'b1;
        @(posedge clk);
        while (!s_tready) @(posedge clk);
        $display("[%d ns] S request: tdata = %h, tkeep = %h, tlast = %h",
            $time, s_tdata, s_tkeep, s_tlast);
        s_tvalid = 1'b0;
    end
    endtask

    task m_chk (
        input [M_TDATA_WIDTH-1:0] tdata,
        input [M_TDATA_BYTES-1:0] tkeep,
        input tlast
    );
    integer delay;
    integer i;
    reg [M_TDATA_WIDTH-1:0] m_tdata_justified;
    begin
        delay = $random % 20;
        while (delay > 0) @(posedge clk) delay = delay - 1;
        m_tready = 1'b1;
        @(posedge clk);
        while (!m_tvalid) @(posedge clk);
        $display("[%d ns] M response: tdata = %h, tkeep = %h, tlast = %h",
            $time, m_tdata, m_tkeep, m_tlast);
        for (i=0; i<M_TDATA_BYTES; i=i+1)
            m_tdata_justified[i*8+:8] = m_tkeep[i] ? m_tdata[i*8+:8] : 8'd0;
        if (m_tdata_justified != tdata) begin
            $display("ERROR: m_tdata mismatch (expected %h but got %h)",
                tdata, m_tdata_justified);
            $fatal;
        end
        if (m_tkeep != tkeep) begin
            $display("ERROR: m_tkeep mismatch (expected %h but got %h)",
                tkeep, m_tkeep);
            $fatal;
        end
        if (m_tlast != tlast) begin
            $display("ERROR: m_tlast mismatch (expected %h but got %h)",
                tlast, m_tlast);
            $fatal;
        end
        m_tready = 1'b0;
    end
    endtask

    task s_thread;
    begin
        // 1
        s_req(16'h1100, 2'b11, 1'b0);
        s_req(16'h3322, 2'b11, 1'b0);
        s_req(16'h5544, 2'b11, 1'b0);
        s_req(16'h7766, 2'b11, 1'b0);
        s_req(16'h9988, 2'b11, 1'b0);
        s_req(16'hbbaa, 2'b11, 1'b0);
        s_req(16'hddcc, 2'b11, 1'b0);
        s_req(16'hffee, 2'b11, 1'b1);
        // 2
        s_req(16'h1100, 2'b11, 1'b0);
        s_req(16'h3322, 2'b11, 1'b0);
        s_req(16'h5544, 2'b11, 1'b0);
        s_req(16'h7766, 2'b11, 1'b0);
        s_req(16'h9988, 2'b11, 1'b0);
        s_req(16'hbbaa, 2'b11, 1'b0);
        s_req(16'hddcc, 2'b11, 1'b0);
        s_req(16'hffee, 2'b11, 1'b0);
        s_req(16'heeff, 2'b11, 1'b0);
        s_req(16'hccdd, 2'b11, 1'b0);
        s_req(16'haabb, 2'b11, 1'b0);
        s_req(16'h8899, 2'b11, 1'b0);
        s_req(16'h6677, 2'b11, 1'b0);
        s_req(16'h4455, 2'b11, 1'b0);
        s_req(16'h2233, 2'b11, 1'b0);
        s_req(16'h0011, 2'b11, 1'b1);
        // 3
        s_req(16'haaaa, 2'b11, 1'b0);
        s_req(16'hbbbb, 2'b11, 1'b0);
        s_req(16'hcccc, 2'b11, 1'b1);
        // 4
        s_req(16'haaaa, 2'b11, 1'b0);
        s_req(16'hbbbb, 2'b11, 1'b0);
        s_req(16'h00cc, 2'b01, 1'b1);
    end
    endtask

    task m_thread;
    begin
        // 1
        m_chk(128'h99887766554433221100, 10'h3ff, 1'b0);
        m_chk(128'h00000000ffeeddccbbaa, 10'h03f, 1'b1);
        // 2
        m_chk(128'h99887766554433221100, 10'h3ff, 1'b0);
        m_chk(128'hccddeeffffeeddccbbaa, 10'h3ff, 1'b0);
        m_chk(128'h2233445566778899aabb, 10'h3ff, 1'b0);
        m_chk(128'h00000000000000000011, 10'h003, 1'b1);
        // 3
        m_chk(128'h00000000ccccbbbbaaaa, 10'h03f, 1'b1);
        // 4
        m_chk(128'h0000000000ccbbbbaaaa, 10'h01f, 1'b1);
    end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        fork
            s_thread();
            m_thread();
        join
        $display("success");
        $finish;
    end

endmodule

`endif // EMULIB_AXIS_WIDTH_UPSIZER_TB
