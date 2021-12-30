#include "kernel/yosys.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct PackageWorker {

    Database &database;
    Design *design;

    void generate_mem_last_i(Module *module, int depth, SigSpec clk, SigSpec scan, SigSpec dir, SigSpec last_i) {
        const int cntbits = ceil_log2(depth + 1);

        // generate last_i signal for mem scan chain
        // delay 1 cycle for scan-out mode to prepare raddr

        // reg [..] cnt;
        // wire full = cnt == depth;
        // always @(posedge clk)
        //   if (!scan)
        //     cnt <= 0;
        //   else if (!full)
        //     cnt <= cnt + 1;
        // reg scan_r;
        // always @(posedge clk) scan_r <= scan;
        // wire ok = dir ? full : scan_r;
        // reg ok_r;
        // always @(posedge clk)
        //    ok_r <= ok;
        // assign last_i = ok && !ok_r;

        SigSpec cnt = module->addWire(NEW_ID, cntbits);
        SigSpec full = module->Eq(NEW_ID, cnt, Const(depth, cntbits));
        module->addSdffe(NEW_ID, clk, module->Not(NEW_ID, full), module->Not(NEW_ID, scan),
            module->Add(NEW_ID, cnt, Const(1, cntbits)), cnt, Const(0, cntbits)); 

        SigSpec scan_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, clk, scan, scan_r);

        SigSpec ok = module->Mux(NEW_ID, scan_r, full, dir);
        SigSpec ok_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, clk, ok, ok_r);

        module->connect(last_i, module->And(NEW_ID, ok, module->Not(NEW_ID, ok_r)));
    }

    void run() {
        ScanChainData &scanchain = database.scanchain;

        Module *top = design->top_module();

        if (!top)
            log_error("No top module found\n");

        if (!top->get_bool_attribute(AttrLibProcessed))
            log_error("Module %s is not processed by emu_process_lib. Run emu_process_lib first.\n", log_id(top));

        if (!top->get_bool_attribute(AttrInstrumented))
            log_error("Module %s is not processed by emu_instrument. Run emu_instrument first.\n", log_id(top));

        design->rename(top, "\\instrumented_user_top");
        top->attributes.erase(ID::top);

        Module *new_top = design->addModule("\\EMU_DUT");
        new_top->set_bool_attribute(ID::top);

        Cell *sub = new_top->addCell("\\dut", top->name);
        
        for (auto portid : top->ports) {
            Wire *port = top->wire(portid);
            Wire *new_port = new_top->addWire(portid, port);
            sub->setPort(portid, new_port);
        }

        Wire *wire_clk        = new_top->wire(PortClk);
        Wire *wire_ram_scan   = new_top->wire(PortRamScanEn);
        Wire *wire_ram_dir    = new_top->wire(PortRamScanDir);
        Wire *wire_ram_last_i = new_top->wire(PortRamLastIn);
        Wire *wire_ram_last_o = new_top->wire(PortRamLastOut);

        wire_ram_last_i->port_input = false;
        wire_ram_last_o->port_output = false;
        new_top->fixup_ports();

        int depth = scanchain.mem_sc_depth();
        generate_mem_last_i(new_top, depth, wire_clk, wire_ram_scan, wire_ram_dir, wire_ram_last_i);
    }

    PackageWorker(Database &database, Design *design) : database(database), design(design) {}

};

struct EmuPackagePass : public Pass {
    EmuPackagePass() : Pass("emu_package", "package design for emulation") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_package [options]\n");
        log("\n");
        log("This command packages the design for emulation by modifying the top module.\n");
        log("\n");
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PACKAGE pass.\n");

        std::string db_name;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-db" && argidx+1 < args.size()) {
                db_name = args[++argidx];
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        Database &db = Database::databases[db_name];

        PackageWorker worker(db, design);
        worker.run();
    }
} EmuPackagePass;

PRIVATE_NAMESPACE_END
