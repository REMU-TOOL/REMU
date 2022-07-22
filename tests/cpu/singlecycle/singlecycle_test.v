`timescale 1 ns / 1 ps

`include "loader.vh"

module sim_top();

    parameter N_CKPT = 2;
    parameter CKPT_PERIOD = 500;

    reg clk = 0, rst = 1;
    reg run_mode = 1, scan_mode = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan_reset = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    EMU_SYSTEM emu_dut(
        .host_clk       (clk),
        .run_mode       (run_mode),
        .scan_mode      (scan_mode),
        .ff_se          (ff_scan),
        .ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .ff_do          (ff_sdo),
        .ram_sr         (ram_scan_reset),
        .ram_se         (ram_scan),
        .ram_sd         (ram_dir),
        .ram_di         (ram_sdi),
        .ram_do         (ram_sdo),
        .target_reset_reset    (rst)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(run_mode),
        .OCLK(ref_clk)
    );

    emu_top emu_ref();

    assign emu_ref.clock.clock = ref_clk;
    assign emu_ref.reset.reset = rst;

    integer i, j;
    reg [`LOAD_MEM_WIDTH-1:0] mem_scan_save [N_CKPT-1:0][`CHAIN_MEM_WORDS-1:0];
    reg [`LOAD_FF_WIDTH-1:0] ff_scan_save [N_CKPT-1:0][`CHAIN_FF_WORDS-1:0];
    reg [63:0] cycle_save [N_CKPT-1:0], finish_cycle;

    always #5 clk = ~clk;

    `LOAD_DECLARE

    reg [63:0] cycle = 0;
    reg finish = 0;
    reg [31:0] result;

    always @(posedge clk) begin
        if (run_mode) begin
            result = emu_ref.u_mem.mem[3];
            if (result != 32'hffffffff && !finish) begin
                $display("Benchmark finished with result = %d at cycle %d", result, cycle);
                finish = 1;
            end
            if (emu_dut.target.u_cpu.rf_wen !== emu_ref.u_cpu.rf_wen ||
                emu_dut.target.u_cpu.rf_waddr !== emu_ref.u_cpu.rf_waddr ||
                emu_dut.target.u_cpu.rf_wdata !== emu_ref.u_cpu.rf_wdata)
            begin
                $display("ERROR: trace mismatch at cycle %d", cycle);
                $display("DUT: wen=%h waddr=%h wdata=%h", emu_dut.target.u_cpu.rf_wen, emu_dut.target.u_cpu.rf_waddr, emu_dut.target.u_cpu.rf_wdata);
                $display("REF: wen=%h waddr=%h wdata=%h", emu_ref.u_cpu.rf_wen, emu_ref.u_cpu.rf_waddr, emu_ref.u_cpu.rf_wdata);
                $fatal;
            end
            cycle <= cycle + 1;
        end
    end

    initial begin
        #30;
        rst = 0;
        // dump checkpoints at different time
        for (i=0; i<N_CKPT; i=i+1) begin
            #(CKPT_PERIOD*10);
            $display("checkpoint %d at cycle %d", i, cycle);
            // pause
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            // dump ff
            ff_scan = 1;
            ff_dir = 0;
            for (j=0; j<`CHAIN_FF_WORDS; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                ff_scan_save[i][j] = ff_sdo;
                #10;
            end
            ff_scan = 0;
            // dump mem
            ram_scan = 1;
            ram_dir = 0;
            #20;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                // randomize backpressure
                ram_scan = 0;
                while (!ram_scan) begin
                    #10;
                    ram_scan = $random;
                end
                mem_scan_save[i][j] = ram_sdo;
                #10;
            end
            ram_scan = 0;
            // save cycle
            cycle_save[i] = cycle;
            #10;
            scan_mode = 0; #10; run_mode = 1;
        end
        while (!finish) #10;
        finish = 0;
        finish_cycle = cycle;
        // restore checkpoints
        for (i=0; i<N_CKPT; i=i+1) begin
            $display("restore checkpoint", i);
            // pause
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            // load ff
            ff_scan = 1;
            ff_dir = 1;
            for (j=0; j<`CHAIN_FF_WORDS; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                ff_sdi = ff_scan_save[i][j];
                #10;
            end
            ff_scan = 0;
            // load mem
            ram_scan = 1;
            ram_dir = 1;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                // randomize backpressure
                ram_scan = 0;
                while (!ram_scan) begin
                    #10;
                    ram_scan = $random;
                end
                ram_sdi = mem_scan_save[i][j];
                #10;
            end
            #10;
            ram_scan = 0;
            #10;
            // load cycle
            cycle = cycle_save[i];
            `LOAD_FF(ff_scan_save[i], 0, emu_ref);
            `LOAD_MEM(mem_scan_save[i], 0, emu_ref);
            scan_mode = 0; #10; run_mode = 1;
            while (!finish) #10;
            finish = 0;
            if (cycle != finish_cycle) begin
                $display("ERROR: DUT finished at different cycle from the first execution");
                $fatal;
            end
        end
        $display("success");
        $finish;
    end

endmodule
