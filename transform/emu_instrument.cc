#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "backends/rtlil/rtlil_backend.h"

#include <queue>

#include "emuutil.h"

using namespace EmuUtil;

#define EMU_NAME(x) (IDGen("\\$EMUGEN." #x "_"))

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

class InsertAccessorWorker {

private:

    static const int ADDR_WIDTH = 12;
    static const int DATA_WIDTH = 64;

    Module *module;
    std::vector<Cell *> ff_cells;
    std::vector<Mem> mem_cells;

    SigSpec wire_reset;
    SigSpec wire_halt;
    SigSpec wire_wen;
    SigSpec wire_waddr;
    SigSpec wire_wdata;
    SigSpec wire_raddr;
    SigSpec wire_rdata;
    SigSpec wire_ram_wid;
    SigSpec wire_ram_wreq;
    SigSpec wire_ram_wdata;
    SigSpec wire_ram_wvalid;
    SigSpec wire_ram_wready;
    SigSpec wire_ram_wlast;
    SigSpec wire_ram_rid;
    SigSpec wire_ram_rreq;
    SigSpec wire_ram_rdata;
    SigSpec wire_ram_rvalid;
    SigSpec wire_ram_rready;
    SigSpec wire_ram_rlast;

    SigSpec process_clock(std::vector<Cell *> &ff_cells, std::vector<Mem> &mem_cells) {
        pool<SigSpec> clocks;
        SigMap assign_map(module);

        for (auto &cell : ff_cells) {
            FfData ff(nullptr, cell);

            if (!ff.has_clk || ff.has_arst || ff.has_sr)
                log_error("Cell type not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));

            if (!ff.pol_clk)
                log_error("Negedge clock polarity not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));

            SigSpec c = assign_map(ff.sig_clk);
            if (c != ff.sig_clk)
                cell->setPort(ID::CLK, c);

            clocks.insert(c);
        }

        for (auto &mem : mem_cells) {
            bool changed = false;
            for (auto &rd : mem.rd_ports) {
                // TODO: check for arst
                if (rd.clk_enable) {
                    if (!rd.clk_polarity)
                        log_error("Negedge clock polarity not supported in mem %s.%s\n", log_id(module), log_id(mem.memid));
                    SigSpec c = assign_map(rd.clk);
                    if (c != rd.clk) {
                        rd.clk = c;
                        changed = true;
                    }
                    clocks.insert(c);
                }
            }
            for (auto &wr : mem.wr_ports) {
                if (!wr.clk_enable)
                    log_error("Mem with asynchronous write port not supported (%s.%s)\n", log_id(module), log_id(mem.cell));
                if (!wr.clk_polarity)
                    log_error("Negedge clock polarity not supported in mem %s.%s\n", log_id(module), log_id(mem.memid));
                SigSpec c = assign_map(wr.clk);
                if (c != wr.clk) {
                    wr.clk = c;
                    changed = true;
                }
                clocks.insert(wr.clk);
            }
            if (changed) mem.emit();
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

    void create_ports() {
        wire_reset      = module->addWire("\\$EMU$RESET");                      wire_reset      .as_wire()->port_input = true;
        wire_halt       = module->addWire("\\$EMU$HALT");                       wire_halt       .as_wire()->port_input = true;
        wire_wen        = module->addWire("\\$EMU$WEN",         DATA_WIDTH);    wire_wen        .as_wire()->port_input = true;
        wire_waddr      = module->addWire("\\$EMU$WADDR",       ADDR_WIDTH);    wire_waddr      .as_wire()->port_input = true;
        wire_wdata      = module->addWire("\\$EMU$WDATA",       DATA_WIDTH);    wire_wdata      .as_wire()->port_input = true;
        wire_raddr      = module->addWire("\\$EMU$RADDR",       ADDR_WIDTH);    wire_raddr      .as_wire()->port_input = true;
        wire_rdata      = module->addWire("\\$EMU$RDATA",       DATA_WIDTH);    wire_rdata      .as_wire()->port_output = true;

        wire_ram_wid    = module->addWire("\\$EMU$RAM$WID",     ADDR_WIDTH);    wire_ram_wid    .as_wire()->port_input = true;
        wire_ram_wreq   = module->addWire("\\$EMU$RAM$WREQ");                   wire_ram_wreq   .as_wire()->port_input = true;
        wire_ram_wdata  = module->addWire("\\$EMU$RAM$WDATA",   DATA_WIDTH);    wire_ram_wdata  .as_wire()->port_input = true;
        wire_ram_wvalid = module->addWire("\\$EMU$RAM$WVALID");                 wire_ram_wvalid .as_wire()->port_input = true;
        wire_ram_wready = module->addWire("\\$EMU$RAM$WREADY");                 wire_ram_wready .as_wire()->port_output = true;
        wire_ram_wlast  = module->addWire("\\$EMU$RAM$WLAST");                  wire_ram_wlast  .as_wire()->port_input = true;
        wire_ram_rid    = module->addWire("\\$EMU$RAM$RID",     ADDR_WIDTH);    wire_ram_rid    .as_wire()->port_input = true;
        wire_ram_rreq   = module->addWire("\\$EMU$RAM$RREQ");                   wire_ram_rreq   .as_wire()->port_input = true;
        wire_ram_rdata  = module->addWire("\\$EMU$RAM$RDATA",   DATA_WIDTH);    wire_ram_rdata  .as_wire()->port_output = true;
        wire_ram_rvalid = module->addWire("\\$EMU$RAM$RVALID");                 wire_ram_rvalid .as_wire()->port_output = true;
        wire_ram_rready = module->addWire("\\$EMU$RAM$RREADY");                 wire_ram_rready .as_wire()->port_input = true;
        wire_ram_rlast  = module->addWire("\\$EMU$RAM$RLAST");                  wire_ram_rlast  .as_wire()->port_output = true;

        module->fixup_ports();
    }

    void instrument_ffs(std::vector<Cell *> &ff_cells, SigSpec clock) {
        // break FFs into signals for packing
        int total_width = 0;
        std::map<int, std::queue<SigSig>> ff_sigs; // width -> {(D, Q)}
        for (auto &cell : ff_cells) {
            FfData ff(nullptr, cell);
            ff.unmap_ce_srst(module);

            // slice signals if width > DATA_WIDTH
            int width = GetSize(ff.sig_d);
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
        ff_cells.clear();
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
                total_packed_width += GetSize(ff.first);
            }
        }
        log("Total width of FFs after packing: %d\n", total_packed_width);
        log_assert(total_width == total_packed_width);

        if (packed_ffs.size() > (1UL << ADDR_WIDTH)) {
            log_error("FF address space is insufficient (%lu required)\n", packed_ffs.size());
        }

        // new FFs indexed by assigned addresses
        int assigned_addr = 0;
        SigSpec read_pmux_b, read_pmux_s;

        // insert read & write logic
        for (auto &ff : packed_ffs) {
            int width = GetSize(ff.first);

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
            ff_cells.push_back(new_ff);

            // signals for read pmux
            SigSpec b = width < DATA_WIDTH ? SigSpec({Const(0, DATA_WIDTH - width), ff_q}) : ff_q;
            SigSpec s = module->Eq(NEW_ID, wire_raddr, Const(assigned_addr, ADDR_WIDTH));
            read_pmux_b.append(b);
            read_pmux_s.append(s);

            // assign address for new FF
            new_ff->set_string_attribute("\\accessor_addr", stringf("%d", assigned_addr));
            if (!new_ff->has_attribute("\\emu_orig"))
                new_ff->set_string_attribute("\\emu_orig", get_sig_src(ff_q));

            assigned_addr++;
        }

        SigSpec pmux = assigned_addr ? module->Pmux(NEW_ID, Const(0, DATA_WIDTH), read_pmux_b, read_pmux_s) : Const(0, DATA_WIDTH);
        module->connect(wire_rdata, pmux);

        log("Assigned FF addresses: %d\n", assigned_addr);
    }

    void instrument_mems(std::vector<Mem> &mem_cells, SigSpec clock) {
        int assigned_id = 0;

        SigSpec wready_pmux_b, wready_pmux_s;
        SigSpec rvalid_pmux_b, rvalid_pmux_s;
        SigSpec rdata_pmux_b, rdata_pmux_s;
        SigSpec rlast_pmux_b, rlast_pmux_s;

        for (auto &mem : mem_cells) {
            const int transfer_beats = (mem.size * mem.width + DATA_WIDTH - 1) / DATA_WIDTH;
            const int cntlen = ceil_log2(transfer_beats + 1);
            const int addrlen = ceil_log2(mem.start_offset + mem.size + 1);

            SigSpec ram_wsel = module->Eq(NEW_ID, wire_ram_wid, Const(assigned_id, ADDR_WIDTH));
            SigSpec ram_rsel = module->Eq(NEW_ID, wire_ram_rid, Const(assigned_id, ADDR_WIDTH));
            SigSpec ram_wreq = module->And(NEW_ID, ram_wsel, wire_ram_wreq);
            SigSpec ram_rreq = module->And(NEW_ID, ram_rsel, wire_ram_rreq);
            SigSpec ram_wvalid = module->And(NEW_ID, ram_wsel, wire_ram_wvalid);
            SigSpec ram_rvalid = module->And(NEW_ID, ram_rsel, wire_ram_rvalid);

            SigSpec ram_wrst = module->Or(NEW_ID, wire_reset, ram_wreq);
            SigSpec ram_rrst = module->Or(NEW_ID, wire_reset, ram_rreq);

            // convert data width to mem width
            WidthAdapterBuilder wr_adapter(module, DATA_WIDTH, mem.width, clock, ram_wrst);
            WidthAdapterBuilder rd_adapter(module, mem.width, DATA_WIDTH, clock, ram_rrst);
            wr_adapter.run();
            rd_adapter.run();

            SigSpec wr_ifire = module->And(NEW_ID, wr_adapter.s_ivalid(), wr_adapter.s_iready());
            SigSpec wr_ofire = module->And(NEW_ID, wr_adapter.s_ovalid(), wr_adapter.s_oready());
            SigSpec rd_ifire = module->And(NEW_ID, rd_adapter.s_ivalid(), rd_adapter.s_iready());
            SigSpec rd_ofire = module->And(NEW_ID, rd_adapter.s_ovalid(), rd_adapter.s_oready());

            // read/write counters & RAM address generators

            SigSpec wr_cnt = module->addWire(EMU_NAME(wr_cnt), cntlen);
            SigSpec wr_cnt_next = module->addWire(EMU_NAME(wr_cnt_next), cntlen);
            SigSpec rd_cnt = module->addWire(EMU_NAME(rd_cnt), cntlen);
            SigSpec rd_cnt_next = module->addWire(EMU_NAME(rd_cnt_next), cntlen);
            SigSpec wr_addr = module->addWire(EMU_NAME(wr_addr), addrlen);
            SigSpec wr_addr_next = module->addWire(EMU_NAME(wr_addr_next), addrlen);
            SigSpec rd_addr = module->addWire(EMU_NAME(rd_addr), addrlen);
            SigSpec rd_addr_next = module->addWire(EMU_NAME(rd_addr_next), addrlen);

            SigSpec wr_cnt_full = module->Eq(NEW_ID, wr_cnt, Const(transfer_beats, cntlen));
            SigSpec rd_cnt_full = module->Eq(NEW_ID, rd_cnt, Const(transfer_beats, cntlen));
            SigSpec wr_addr_full = module->Eq(NEW_ID, wr_addr, Const(mem.start_offset + mem.size, addrlen));
            SigSpec rd_addr_full = module->Eq(NEW_ID, rd_addr, Const(mem.start_offset + mem.size, addrlen));

            SigSpec wr_cnt_not_full = module->Not(NEW_ID, wr_cnt_full);
            SigSpec rd_cnt_not_full = module->Not(NEW_ID, rd_cnt_full);
            SigSpec wr_addr_not_full = module->Not(NEW_ID, wr_addr_full);
            SigSpec rd_addr_not_full = module->Not(NEW_ID, rd_addr_full);

            SigSpec mem_rfire = module->addWire(EMU_NAME(mem_rfire));

            module->addSdffe(NEW_ID, clock, module->And(NEW_ID, wr_ifire, wr_cnt_not_full), ram_wrst, wr_cnt_next, wr_cnt, Const(0, cntlen));
            module->addSdffe(NEW_ID, clock, module->And(NEW_ID, rd_ofire, rd_cnt_not_full), ram_rrst, rd_cnt_next, rd_cnt, Const(0, cntlen));
            module->addSdffe(NEW_ID, clock, module->And(NEW_ID, wr_ofire, wr_addr_not_full), ram_wrst, wr_addr_next, wr_addr, Const(mem.start_offset, addrlen));
            module->addSdffe(NEW_ID, clock, module->And(NEW_ID, mem_rfire, rd_addr_not_full), ram_rrst, rd_addr_next, rd_addr, Const(mem.start_offset, addrlen));

            module->connect(wr_cnt_next, module->Add(NEW_ID, wr_cnt, Const(1, cntlen)));
            module->connect(rd_cnt_next, module->Add(NEW_ID, rd_cnt, Const(1, cntlen)));
            module->connect(wr_addr_next, module->Add(NEW_ID, wr_addr, Const(1, addrlen)));
            module->connect(rd_addr_next, module->Add(NEW_ID, rd_addr, Const(1, addrlen)));

            // internal connections

            module->connect(wr_adapter.s_ivalid(), ram_wvalid);
            wready_pmux_b.append(wr_adapter.s_iready());
            wready_pmux_s.append(ram_wsel);
            module->connect(wr_adapter.s_idata(), wire_ram_wdata);
            module->connect(wr_adapter.s_oready(), State::S1);

            // delay 1 cycle to sync with the synchronous read port
            SigSpec mem_rvalid_r = module->addWire(EMU_NAME(mem_rvalid_r));
            SigSpec mem_rvalid = module->And(NEW_ID, ram_rsel, rd_cnt_not_full);
            SigSpec mem_rready = module->Or(NEW_ID, rd_adapter.s_iready(), module->Not(NEW_ID, mem_rvalid));
            module->addSdff(NEW_ID, clock, ram_rrst, module->Xor(NEW_ID, mem_rvalid_r, module->Xor(NEW_ID, mem_rfire, rd_ifire)), mem_rvalid_r, Const(0, 1));
            module->connect(mem_rfire, module->And(NEW_ID, mem_rvalid, mem_rready));

            module->connect(rd_adapter.s_ivalid(), mem_rvalid_r);
            rvalid_pmux_b.append(rd_adapter.s_ovalid());
            rvalid_pmux_s.append(ram_rsel);
            rdata_pmux_b.append(rd_adapter.s_odata());
            rdata_pmux_s.append(ram_rsel);
            module->connect(rd_adapter.s_oready(), wire_ram_rready);

            SigSpec rlast = module->Eq(NEW_ID, rd_cnt, Const(transfer_beats - 1, cntlen));

            module->connect(wr_adapter.s_flush(), module->And(NEW_ID, wr_cnt_full, wr_addr_not_full));
            module->connect(rd_adapter.s_flush(), module->And(NEW_ID, rd_addr_full, rd_cnt_not_full));
            rlast_pmux_b.append(rlast);
            rlast_pmux_s.append(ram_rsel);

            // instrument read/write ports

            const int abits = ceil_log2(mem.start_offset + mem.size);

            SigSpec ram_wen = module->And(NEW_ID, wr_ofire, wr_addr_not_full);

            // add halt signal to ports
            for (auto &wr : mem.wr_ports) {
                wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), wire_halt);
            }

            // add accessor to write port 0
            auto &wr = mem.wr_ports[0];
            wr.en = module->Mux(NEW_ID, wr.en, SigSpec(ram_wen, mem.width), wire_halt);
            if (abits > 0)
                wr.addr = module->Mux(NEW_ID, wr.addr, wr_addr.extract(0, abits), wire_halt);
            wr.data = module->Mux(NEW_ID, wr.data, wr_adapter.s_odata(), wire_halt);

            // add accessor to read port 0
            auto &rd = mem.rd_ports[0];
            if (abits > 0)
                rd.addr = module->Mux(NEW_ID, rd.addr, rd_addr.extract(0, abits), wire_halt);
            if (rd.clk_enable) {
                // TODO: do not use rd.en
                //rd.en = module->Mux(NEW_ID, rd.en, module->And(NEW_ID, ram_rsel, mem_rready), wire_halt);
                module->connect(rd_adapter.s_idata(), rd.data);
            }
            else {
                // delay 1 cycle for asynchronous read ports
                SigSpec mem_rdata = module->addWire(EMU_NAME(mem_rdata), mem.width);
                module->addDffe(NEW_ID, clock, mem_rready, rd.data, mem_rdata);
                module->connect(rd_adapter.s_idata(), mem_rdata);
            }

            mem.packed = true;
            mem.set_string_attribute("\\accessor_id", stringf("%d", assigned_id));
            mem.emit();

            assigned_id++;
        }

        module->connect(wire_ram_wready, assigned_id ? module->Pmux(NEW_ID, State::S0, wready_pmux_b, wready_pmux_s) : State::S0);
        module->connect(wire_ram_rvalid, assigned_id ? module->Pmux(NEW_ID, State::S0, rvalid_pmux_b, rvalid_pmux_s) : State::S0);
        module->connect(wire_ram_rdata, assigned_id ? module->Pmux(NEW_ID, Const(0, DATA_WIDTH), rdata_pmux_b, rdata_pmux_s) : Const(0, DATA_WIDTH));
        module->connect(wire_ram_rlast, assigned_id ? module->Pmux(NEW_ID, State::S0, rlast_pmux_b, rlast_pmux_s) : State::S0);

        log("Assigned mem IDs: %d\n", assigned_id);
    }

    void restore_mem_rdport_ffs(std::vector<Mem> &mem_cells, std::vector<Cell *> &ff_cells) {
        for (auto &mem : mem_cells) {
            for (auto &rd : mem.rd_ports) {
                if (rd.clk_enable) {
                    if (mem.has_attribute("\\emu_orig_raddr")) {
                        SigSpec ff_q = module->addWire(EMU_NAME(restored_raddr), GetSize(rd.addr));
                        Cell *ff = module->addDff(NEW_ID, rd.clk, rd.addr, ff_q);
                        ff->set_string_attribute("\\emu_orig", mem.get_string_attribute("\\emu_orig_raddr"));
                        ff_cells.push_back(ff);
                    }
                    else if (mem.has_attribute("\\emu_orig_rdata")) {
                        SigSpec ff_q = module->addWire(EMU_NAME(restored_rdata), GetSize(rd.data));
                        Cell *ff = module->addDff(NEW_ID, rd.clk, rd.data, ff_q);
                        ff->set_string_attribute("\\emu_orig", mem.get_string_attribute("\\emu_orig_rdata"));
                        ff_cells.push_back(ff);
                        // TODO: use specialized halt signal
                    }
                    else {
                        log_error(
                            "%s.%s: Memory has synchronous read port without source information. \n"
                            "Run emu_opt_ram instead of memory_dff.",
                            log_id(module), log_id(mem.cell));
                    }
                }
            }
        }
    }

public:

    InsertAccessorWorker(Module *mod) : module(mod) {}

    void run() {
        // check if already processed
        if (module->get_bool_attribute("\\emu_instrumented")) {
            log_warning("Module %s is already processed by emu_instrument\n", log_id(module));
            return;
        }

        // RTLIL processes & memories are not accepted
        if (module->has_processes_warn() || module->has_memories_warn())
            return;

        // search for all FFs
        for (auto cell : module->cells())
            if (module->design->selected(module, cell) && RTLIL::builtin_ff_cell_types().count(cell->type))
                if (!cell->get_bool_attribute("\\emu_internal"))
                    ff_cells.push_back(cell);

        // get mem cells
        mem_cells = Mem::get_selected_memories(module);

        // exclude mem cells without write ports (ROM)
        for (auto it = mem_cells.begin(); it != mem_cells.end(); )
            if (it->wr_ports.size() == 0)
                it = mem_cells.erase(it);
            else
                ++it;

        // find the clock signal
        SigSpec clock = process_clock(ff_cells, mem_cells);

        // if no clock is found, then this module does not contain sequential logic
        if (clock.empty())
            return;

        // add accessor ports
        create_ports();

        // restore merged ffs in read ports
        restore_mem_rdport_ffs(mem_cells, ff_cells);

        // process FFs
        instrument_ffs(ff_cells, clock);

        // process mems
        instrument_mems(mem_cells, clock);

        // set attribute to indicate this module is processed
        module->set_bool_attribute("\\emu_instrumented");
    }

    void write_config(std::string filename) {
        std::ofstream f;
        f.open(filename.c_str(), std::ofstream::trunc);
        if (f.fail()) {
            log_error("Can't open file `%s' for writing: %s\n", filename.c_str(), strerror(errno));
        }

        log("Writing to configuration file %s\n", filename.c_str());

        f << "#FF\n";
        for (auto &ff : ff_cells) {
            std::string addr = ff->get_string_attribute("\\accessor_addr");
            int new_offset = 0;
            for (auto &s : parse_sig_src(ff->get_string_attribute("\\emu_orig"))) {
                std::string &name = std::get<0>(s);
                int offset = std::get<1>(s), width = std::get<2>(s);
                if (name[0] == '\\') {
                    f   << addr << "," << new_offset << ": " << name.substr(1)
                        << "[" << offset + width - 1 << ":" << offset << "]\n";
                }
                new_offset += width;
            }
        }

        f << "#MEM\n";
        for (auto &mem : mem_cells) {
            std::string name = mem.memid.str();
            if (name[0] == '\\') {
                f   << mem.cell->get_string_attribute("\\accessor_id")
                    << ": " << name.substr(1) << "\n";
            }
        }

        f.close();
    }

    void write_loader(std::string filename) {
        std::ofstream f;
        f.open(filename.c_str(), std::ofstream::trunc);
        if (f.fail()) {
            log_error("Can't open file `%s' for writing: %s\n", filename.c_str(), strerror(errno));
        }

        log("Writing to loader file %s\n", filename.c_str());

        f << "`define LOADER_DEFS reg [" << DATA_WIDTH - 1 << ":0] __reconstructed_ffs [" << ff_cells.size() - 1 << ":0];\n";
        f << "`define LOADER_STMTS \\\n";

        f << stringf("    $readmemh({`CHECKPOINT_PATH, \"/ffdata.txt\"}, __reconstructed_ffs);\\\n");
        for (auto &ff : ff_cells) {
            std::string addr = ff->get_string_attribute("\\accessor_addr");
            int new_offset = 0;
            for (auto &s : parse_sig_src(ff->get_string_attribute("\\emu_orig"))) {
                std::string &name = std::get<0>(s);
                int offset = std::get<1>(s), width = std::get<2>(s);
                if (name[0] == '\\') {
                    f   << "    `DUT_INST." << name.substr(1)
                        << "[" << offset + width - 1 << ":" << offset << "]"
                        << " = __reconstructed_ffs[" << addr << "]"
                        << "[" << new_offset + width - 1 << ":" << new_offset << "];\\\n";
                }
                new_offset += width;
            }
        }

        for (auto &mem : mem_cells) {
            std::string name = mem.memid.str();
            if (name[0] == '\\') {
                f   << "    $readmemh({`CHECKPOINT_PATH, \"/mem_"
                    << mem.cell->get_string_attribute("\\accessor_id")
                    << ".txt\"}, `DUT_INST." << name.substr(1) << ");\\\n";
            }
        }

        f << "\n";
        f.close();
    }
};

struct EmuInstrumentPass : public Pass {
    EmuInstrumentPass() : Pass("emu_instrument", "insert accessors for emulation") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_instrument [options]\n");
        log("\n");
        log("This command inserts accessors to FFs and mems for an FPGA emulator.\n");
        log("\n");
        log("    -cfg <file>\n");
        log("        write generated configuration to the specified file\n");
        log("    -ldr <file>\n");
        log("        write generated simulation loader to the specified file\n");
        log("\n");
    }

    std::string cfg_file, ldr_file;

    void execute(vector<string> args, Design* design) override {
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-cfg" && argidx+1 < args.size()) {
                cfg_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-ldr" && argidx+1 < args.size()) {
                ldr_file = args[++argidx];
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        log_header(design, "Executing EMU_INSTRUMENT pass.\n");

        for (auto mod : design->modules()) {
            if (design->selected(mod)) {
                log("Processing module %s\n", mod->name.c_str());
                InsertAccessorWorker worker(mod);
                worker.run();
                if (!cfg_file.empty()) worker.write_config(cfg_file);
                if (!ldr_file.empty()) worker.write_loader(ldr_file);
            }
        }
    }
} InsertAccessorPass;

PRIVATE_NAMESPACE_END
