#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "backends/rtlil/rtlil_backend.h"

#include <queue>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

class InsertAccessorWorker {

private:

    static const int ADDR_WIDTH = 12;
    static const int DATA_WIDTH = 64;
    Module *module;

    SigSpec wire_halt;
    SigSpec wire_wen;
    SigSpec wire_waddr;
    SigSpec wire_wdata;
    SigSpec wire_raddr;
    SigSpec wire_rdata;
    SigSpec wire_ramid;
    SigSpec wire_ram_wreq;
    SigSpec wire_ram_wdata;
    SigSpec wire_ram_wvalid;
    SigSpec wire_ram_wready;
    SigSpec wire_ram_wdone;
    SigSpec wire_ram_rreq;
    SigSpec wire_ram_rdata;
    SigSpec wire_ram_rvalid;
    SigSpec wire_ram_rready;
    SigSpec wire_ram_rdone;

    SigSpec find_ff_clock(const std::vector<Cell *> &ff_cells) {
        pool<SigSpec> clocks;

        for (auto cell : ff_cells) {
            FfData ff(nullptr, cell);

            if (!ff.has_clk || ff.has_arst || ff.has_sr)
                log_error("Cell type not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));

            if (!ff.pol_clk)
                log_error("Negedge clock polarity not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));

            clocks.insert(ff.sig_clk);
        }

        if (clocks.size() > 1) {
            std::cerr << "Multiple clocks detected:\n";
            for (SigSpec s : clocks) {
                std::cerr << "\t";
                RTLIL_BACKEND::dump_sigspec(std::cerr, s);
                std::cerr << "\n";
            }
            log_error("Multiple clock domains not supported (in module %s)\n", log_id(module));
        }

        if (clocks.empty())
            return SigSpec();

        return clocks.pop();
    }

    void check_mem(const std::vector<Mem> &mem_cells, SigSpec clock) {
        for (auto mem : mem_cells) {
            for (auto rd : mem.rd_ports) {
                if (rd.clk_enable && rd.clk != clock) {
                    log_error("The clock domains of mem %s.%s and FFs differ\n", log_id(module), log_id(mem.cell));
                }
            }
            for (auto wr : mem.wr_ports) {
                if (!wr.clk_enable) {
                    log_error("Mem with asynchronous write port not supported (%s.%s)\n", log_id(module), log_id(mem.cell));
                }
                if (wr.clk != clock) {
                    log_error("The clock domains of mem %s.%s and FFs differ\n", log_id(module), log_id(mem.cell));
                }
            }
        }
    }

    void create_ports() {
        wire_halt       = module->addWire("\\$EMU$HALT");                       wire_halt       .as_wire()->port_input = true;
        wire_wen        = module->addWire("\\$EMU$WEN",         DATA_WIDTH);    wire_wen        .as_wire()->port_input = true;
        wire_waddr      = module->addWire("\\$EMU$WADDR",       ADDR_WIDTH);    wire_waddr      .as_wire()->port_input = true;
        wire_wdata      = module->addWire("\\$EMU$WDATA",       DATA_WIDTH);    wire_wdata      .as_wire()->port_input = true;
        wire_raddr      = module->addWire("\\$EMU$RADDR",       ADDR_WIDTH);    wire_raddr      .as_wire()->port_input = true;
        wire_rdata      = module->addWire("\\$EMU$RDATA",       DATA_WIDTH);    wire_rdata      .as_wire()->port_output = true;

        wire_ramid      = module->addWire("\\$EMU$RAMID",       ADDR_WIDTH);    wire_ramid      .as_wire()->port_input = true;
        wire_ram_wreq   = module->addWire("\\$EMU$RAM$WREQ");                   wire_ram_wreq   .as_wire()->port_input = true;
        wire_ram_wdata  = module->addWire("\\$EMU$RAM$WDATA",   DATA_WIDTH);    wire_ram_wdata  .as_wire()->port_input = true;
        wire_ram_wvalid = module->addWire("\\$EMU$RAM$WVALID");                 wire_ram_wvalid .as_wire()->port_input = true;
        wire_ram_wready = module->addWire("\\$EMU$RAM$WREADY");                 wire_ram_wready .as_wire()->port_output = true;
        wire_ram_wdone  = module->addWire("\\$EMU$RAM$WDONE");                  wire_ram_wdone  .as_wire()->port_output = true;
        wire_ram_rreq   = module->addWire("\\$EMU$RAM$RREQ");                   wire_ram_rreq   .as_wire()->port_input = true;
        wire_ram_rdata  = module->addWire("\\$EMU$RAM$RDATA",   DATA_WIDTH);    wire_ram_rdata  .as_wire()->port_output = true;
        wire_ram_rvalid = module->addWire("\\$EMU$RAM$RVALID");                 wire_ram_rvalid .as_wire()->port_output = true;
        wire_ram_rready = module->addWire("\\$EMU$RAM$RREADY");                 wire_ram_rready .as_wire()->port_input = true;
        wire_ram_rdone  = module->addWire("\\$EMU$RAM$RDONE");                  wire_ram_rdone  .as_wire()->port_output = true;

        module->fixup_ports();
    }

    void process_ffs(const std::vector<Cell *> &ff_cells, SigSpec clock) {
        // break FFs into signals for packing
        int total_width = 0;
        std::map<int, std::queue<SigSig>> ff_sigs; // width -> {(D, Q)}
        for (auto cell : ff_cells) {
            FfData ff(nullptr, cell);
            ff.unmap_ce_srst(module);

            // slice signals if width > DATA_WIDTH
            int width = ff.sig_d.size();
            for (int i = 0; i < width; i += DATA_WIDTH) {
                int slice = width - i;
                slice = slice > DATA_WIDTH ? DATA_WIDTH : slice;
                SigSpec d = ff.sig_d.extract(i, slice);
                SigSpec q = ff.sig_q.extract(i, slice);
                ff_sigs[slice].push({d, q});
            }
            total_width += width;

            module->remove(cell);
        }
        log("Total width of FFs: %d\n", total_width);

        // pack new FFs
        int total_packed_width = 0;
        std::vector<SigSig> packed_ffs;
        for (auto kv = ff_sigs.rbegin(); kv != ff_sigs.rend(); ++kv) {
            while (!kv->second.empty()) {
                SigSig ff = kv->second.front(); kv->second.pop();
                int packed = kv->first;

                //log("current: %d\n", packed);
                while (packed < DATA_WIDTH) {    
                    //log("packed: %d\n", packed);
                    int i;
                    // pick another FF to pack (try complement size first)
                    for (i = DATA_WIDTH; i > 0; i--) {
                        int w = i - packed;
                        if (w <= 0) w += DATA_WIDTH;
                        //log("w: %d(%d)\n", w, kv->first);
                        if (ff_sigs.find(w) != ff_sigs.end() && !ff_sigs[w].empty()) {
                            SigSig pick = ff_sigs[w].front(); ff_sigs[w].pop();
                            ff.first.append(pick.first);
                            ff.second.append(pick.second);
                            packed += w;
                            break;
                        }
                    }
                    // no more FFs to pack, stop
                    if (i == 0) break;
                }
                //log("final size: %d\n", packed);

                // slice if oversized
                if (packed > DATA_WIDTH) {
                    int w = packed - DATA_WIDTH;

                    ff_sigs[w].push(SigSig(
                        ff.first.extract(DATA_WIDTH, w),
                        ff.second.extract(DATA_WIDTH, w)
                    ));

                    ff.first = ff.first.extract(0, DATA_WIDTH);
                    ff.second = ff.second.extract(0, DATA_WIDTH);
                }

                packed_ffs.push_back(ff);
                total_packed_width += ff.first.size();
            }
        }
        log("Total width of FFs after packing: %d\n", total_packed_width);
        log_assert(total_width == total_packed_width);

        if (packed_ffs.size() > (1UL << ADDR_WIDTH)) {
            log_error("FF address space is insufficient (%lu required)\n", packed_ffs.size());
        }

        // new FFs indexed by assigned addresses
        int assigned_addr = 0;
        dict<Cell*, int> addr_map;

        // insert write logic
        for (auto ff : packed_ffs) {
            int width = ff.first.size();

            // generate write control signal
            SigSpec ff_sel = module->Eq(NEW_ID, wire_waddr, Const(assigned_addr, ADDR_WIDTH));
            SigSpec ff_wen = module->Mux(NEW_ID, Const(0, width), wire_wen.extract(0, width), ff_sel);

            // signals for new FF
            SigSpec ff_q = ff.second;
            SigSpec ff_wdata = module->Or(NEW_ID,
                module->And(NEW_ID, ff_q, module->Not(NEW_ID, ff_wen)),
                module->And(NEW_ID, wire_wdata.extract(0, width), ff_wen)
            );
            SigSpec ff_d = module->Mux(NEW_ID, ff.first, ff_wdata, wire_halt);

            // create new FF
            Cell *new_ff = module->addDff(NEW_ID, clock, ff_d, ff_q);

            // save original register names
            std::stringstream regnames;
            for (SigChunk chunk : ff_q.chunks()) {
                log_assert(chunk.is_wire());
                regnames    << chunk.wire->name.c_str()
                            << "[" << chunk.offset+chunk.width-1 << ":" << chunk.offset << "];";
            }
            new_ff->set_string_attribute("\\accessor_name", regnames.str());

            // assign address for new FF
            new_ff->set_string_attribute("\\accessor_addr", stringf("%d", assigned_addr));
            addr_map[new_ff] = assigned_addr;
            assigned_addr++;
        }
        log("insert_accessor assigned addresses: %d\n", assigned_addr);

        // insert read logic
        SigSpec read_pmux_b, read_pmux_s;
        for (auto pair : addr_map) {
            Cell *cell = pair.first;
            int addr = pair.second;
            int width = cell->getParam(ID::WIDTH).as_int();

            SigSpec ff_q = cell->getPort(ID::Q);
            SigSpec b = width < DATA_WIDTH ? SigSpec({Const(0, DATA_WIDTH - width), ff_q}) : ff_q;
            SigSpec s = module->Eq(NEW_ID, wire_raddr, Const(addr, ADDR_WIDTH));
            read_pmux_b.append(b);
            read_pmux_s.append(s);
        }
        SigSpec pmux = module->Pmux(NEW_ID, Const(0, DATA_WIDTH), read_pmux_b, read_pmux_s);
        module->addDff(NEW_ID, clock, pmux, wire_rdata);
    }

    void process_mems(const std::vector<Mem> &mem_cells, SigSpec clock) {
        for (auto mem : mem_cells) {
        }
    }

public:

    InsertAccessorWorker(Module *mod) : module(mod) {}

    void run() {
        // check if already processed
        if (module->get_bool_attribute("\\insert_accessor")) {
            log_warning("Module %s is already processed by insert_accessor\n", log_id(module));
            return;
        }

        // RTLIL proceesses are not accepted
        if (!module->processes.empty())
            log_error("Module %s contains unmapped RTLIL processes. Use \"proc\"\n"
				"to convert processes to logic networks and registers.\n", log_id(module));

        // search for all FFs
        std::vector<Cell *> ff_cells;
        for (auto cell : module->cells()) {
			if (module->design->selected(module, cell) && RTLIL::builtin_ff_cell_types().count(cell->type))
				ff_cells.push_back(cell);
		}

        SigSpec clock = find_ff_clock(ff_cells);

        // if no clock is found, then this module does not contain sequential logic
        if (clock.empty())
            return;

        // get mem cells
        std::vector<Mem> mem_cells;
        mem_cells = Mem::get_selected_memories(module);
        check_mem(mem_cells, clock);

        // add accessor ports
        create_ports();

        // process FFs
        process_ffs(ff_cells, clock);

        // process mems
        process_mems(mem_cells, clock);

        // set attribute to indicate this module is processed
        module->set_bool_attribute("\\insert_accessor");
    }
};

struct InsertAccessorPass : public Pass {
    InsertAccessorPass() : Pass("insert_accessor") { }
    void execute(vector<string> args, Design* design) override {
        (void)args;

        log_header(design, "Executing INSERT_ACCESSOR pass.\n");

        for (auto mod : design->modules()) {
            if (design->selected(mod)) {
                InsertAccessorWorker worker(mod);
                worker.run();
            }
        }
    }
} InsertAccessorPass;

PRIVATE_NAMESPACE_END
