#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "backends/rtlil/rtlil_backend.h"

#include <queue>

#include "emuutil.h"

using namespace EmuUtil;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

std::string EmuIDGen(std::string file, int line, std::string function, std::string name) {
    std::ostringstream s;
    s << "\\$EMUGEN." << name << "$" << file << ":" << line << "@" << function << "#";
    return IDGen(s.str());
}

#define EMU_NAME(x) (EmuIDGen(__FILE__, __LINE__, __FUNCTION__, #x))

class ScanChainBase {

protected:

    // (source info, num of words to transfer)
    using SrcType = std::vector<std::pair<std::string, int>>;

    ScanChainBase() : depth_(0) {}

#define DEF_PROP(t, x) protected: t x##_; public: t x() { return x##_; }
#define DEF_REF_PROP(t, x) protected: t x##_; public: t& x() { return x##_; }
    DEF_PROP(Wire *, data_i)
    DEF_PROP(Wire *, data_o)
    DEF_PROP(Wire *, last_i)
    DEF_PROP(Wire *, last_o)
    DEF_PROP(int, depth) // num of layers of scan registers
    DEF_REF_PROP(SrcType, src)
#undef DEF_PROP
#undef DEF_REF_PROP

};

// scan chain building block
class ScanChainBlock : public ScanChainBase {

    friend class ScanChain;

protected:
    ScanChainBlock() {}

public:
    int &depth() { return depth_; }
};

// a whole scan chain connecting scan chain blocks
class ScanChain : public ScanChainBase {

    Module *module;
    ScanChainBlock *active_block;

public:
    ScanChain(Module *module, int width) {
        this->module = module;
        data_i_ = data_o_ = module->addWire(NEW_ID, width);
        last_i_ = last_o_ = module->addWire(NEW_ID);
        active_block = 0;
    }

    ~ScanChain() {
        log_assert(active_block == 0);
    }

    ScanChainBlock &new_block() {
        log_assert(active_block == 0);

        active_block = new ScanChainBlock;
        active_block->data_o_ = data_i_;
        active_block->last_i_ = last_o_;
        active_block->data_i_ = data_i_ = module->addWire(NEW_ID, data_i_->width);
        active_block->last_o_ = last_o_ = module->addWire(NEW_ID);

        return *active_block;
    }

    void commit_block() {
        log_assert(active_block != 0);

        depth_ += active_block->depth_;
        src_.insert(src_.end(), active_block->src_.begin(), active_block->src_.end());

        delete active_block;
        active_block = 0;
    }

};

class InsertAccessorWorker {

private:

    static const int DATA_WIDTH = 64;

    Module *module;

    ScanChain *ff_scanchain, *mem_scanchain;

    Wire *wire_clk, *wire_halt;
    Wire *wire_ff_scan, *wire_ff_sdi, *wire_ff_sdo;
    Wire *wire_ram_scan, *wire_ram_dir, *wire_ram_sdi, *wire_ram_sdo; // dir: 0=out 1=in

    void process_clock(std::vector<Cell *> &ff_cells, std::vector<Mem> &mem_cells) {
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
            log_error("No clock found in module %s\n", log_id(module));

        // fix clock connections
        Wire *c = clocks.pop().as_wire();
        c->port_input = false;
        module->connect(c, wire_clk);
        module->fixup_ports();
    }

    void create_ports() {
        wire_clk        = module->addWire("\\$EMU$CLK");                        wire_clk        ->port_input = true;
        wire_halt       = module->addWire("\\$EMU$HALT");                       wire_halt       ->port_input = true;
        wire_ff_scan    = module->addWire("\\$EMU$FF$SCAN");                    wire_ff_scan    ->port_input = true;
        wire_ff_sdi     = module->addWire("\\$EMU$FF$SDI",      DATA_WIDTH);    wire_ff_sdi     ->port_input = true;
        wire_ff_sdo     = module->addWire("\\$EMU$FF$SDO",      DATA_WIDTH);    wire_ff_sdo     ->port_output = true;
        wire_ram_scan   = module->addWire("\\$EMU$RAM$SCAN");                   wire_ram_scan   ->port_input = true;
        wire_ram_dir    = module->addWire("\\$EMU$RAM$DIR");                    wire_ram_dir    ->port_input = true;
        wire_ram_sdi    = module->addWire("\\$EMU$RAM$SDI",     DATA_WIDTH);    wire_ram_sdi    ->port_input = true;
        wire_ram_sdo    = module->addWire("\\$EMU$RAM$SDO",     DATA_WIDTH);    wire_ram_sdo    ->port_output = true;

        module->fixup_ports();
    }

    void instrument_ffs(std::vector<Cell *> &ff_cells, ScanChainBlock &block) {
        SigSpec sdi, sdo;
        sdi = block.data_o();

        // break FFs into signals for packing
        int total_width = 0;
        std::map<int, std::queue<SigSig>> ff_sigs; // width -> {(D, Q)}
        for (auto &cell : ff_cells) {
            FfData ff(nullptr, cell);
            // TODO: avoid unmapping ce & srst to reduce overhead
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

                sdo = sdi;
                sdi = module->addWire(EMU_NAME(scandata), DATA_WIDTH);

                // create instrumented FF
                // always @(posedge clk)
                //   if (!halt || se)
                //     q <= se ? sdi : d;
                Cell *new_ff = module->addDffe(NEW_ID, wire_clk,
                    module->Or(NEW_ID, module->Not(NEW_ID, wire_halt), wire_ff_scan),
                    module->Mux(NEW_ID, {Const(0, DATA_WIDTH - packed), ff.first}, sdi, wire_ff_scan), sdo);
                ff_cells.push_back(new_ff);
                module->connect(ff.second, sdo.extract(0, packed));

                block.depth()++;
                block.src().push_back({SrcInfo(ff.second), 1});

                total_packed_width += GetSize(ff.first);
            }
        }
        module->connect(block.data_i(), sdi);
        log("Total width of FFs after packing: %d\n", total_packed_width);
    }

    void instrument_mems(std::vector<Mem> &mem_cells, ScanChain &chain) {
        for (auto &mem : mem_cells) {
            auto &block = chain.new_block();

            const int init_addr = mem.start_offset;
            const int last_addr = mem.start_offset + mem.size - 1;
            const int abits = ceil_log2(last_addr);
            const int slices = (mem.width + DATA_WIDTH - 1) / DATA_WIDTH;

            SigSpec inc = module->addWire(EMU_NAME(inc));

            // address generator
            // always @(posedge clk)
            //   if (!scan) addr <= 0;
            //   else if (inc) addr <= addr + 1;
            SigSpec addr = module->addWire(EMU_NAME(addr), abits);
            module->addSdffe(NEW_ID, wire_clk, inc, module->Not(NEW_ID, wire_ram_scan),
                module->Add(NEW_ID, addr, Const(1, abits)), addr, Const(init_addr, abits));

            // assign addr_is_last = addr == last_addr;
            SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(last_addr, abits));

            // shift counter
            // always @(posedge clk)
            //   if (!scan) scnt <= 0;
            //   else scnt <= {scnt[slices-2:0], inc && !addr_is_last};
            SigSpec scnt = module->addWire(EMU_NAME(scnt), slices);
            module->addSdff(NEW_ID, wire_clk, module->Not(NEW_ID, wire_ram_scan), 
                {scnt.extract(0, slices-1), module->And(NEW_ID, inc, module->Not(NEW_ID, addr_is_last))},
                scnt, Const(0, slices));
            SigSpec scnt_msb = scnt.extract(slices-1);

            // if (mem.size > 1)
            //   assign last_o = scnt[slices-1] && addr_is_last
            // else
            //   assign last_o = last_i
            if (mem.size > 1)
                module->connect(block.last_o(), module->And(NEW_ID, scnt_msb, addr_is_last));
            else
                module->connect(block.last_o(), block.last_i());

            // assign inc = scnt[slices-1] || last_i;
            module->connect(inc, module->Or(NEW_ID, scnt_msb, block.last_i()));

            SigSpec se = module->addWire(EMU_NAME(se));
            SigSpec we = module->addWire(EMU_NAME(we));
            SigSpec rdata = module->addWire(EMU_NAME(rdata), mem.width);
            SigSpec wdata = module->addWire(EMU_NAME(wdata), mem.width);

            // create scan chain registers
            SigSpec sdi, sdo;
            sdi = block.data_o();
            for (int i = 0; i < slices; i++) {
                int off = i * DATA_WIDTH;
                int len = mem.width - off;
                if (len > DATA_WIDTH) len = DATA_WIDTH;

                sdo = sdi;
                sdi = module->addWire(EMU_NAME(scan_data), DATA_WIDTH);

                // always @(posedge clk)
                //   r <= se ? sdi : rdata[off+:len];
                // assign sdo = r;
                SigSpec rdata_slice = {Const(0, DATA_WIDTH - len), rdata.extract(off, len)};
                module->addDff(NEW_ID, wire_clk, 
                    module->Mux(NEW_ID, rdata_slice, sdi, se), sdo);
                module->connect(wdata.extract(off, len), sdo.extract(0, len));
            }
            module->connect(block.data_i(), sdi);
            block.depth() = slices;

            // assign se = dir || !inc;
            // assign we = dir && inc;
            module->connect(se, module->Or(NEW_ID, wire_ram_dir, module->Not(NEW_ID, inc)));
            module->connect(we, module->And(NEW_ID, wire_ram_dir, inc));

            // add halt signal to ports
            for (auto &wr : mem.wr_ports) {
                wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), wire_halt);
            }

            // add accessor to write port 0
            auto &wr = mem.wr_ports[0];
            wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), wire_halt);
            if (abits > 0)
                wr.addr = module->Mux(NEW_ID, wr.addr, addr, wire_halt);
            wr.data = module->Mux(NEW_ID, wr.data, wdata, wire_halt);

            // add accessor to read port 0
            auto &rd = mem.rd_ports[0];
            if (abits > 0)
                rd.addr = module->Mux(NEW_ID, rd.addr, addr, wire_halt);
            if (rd.clk_enable) {
                module->connect(rdata, rd.data);
            }
            else {
                // delay 1 cycle for asynchronous read ports
                SigSpec rdata_reg = module->addWire(EMU_NAME(rdata_reg), mem.width);
                module->addDff(NEW_ID, wire_clk, rd.data, rdata_reg);
                module->connect(rdata, rdata_reg);
            }

            mem.packed = true;
            mem.emit();

            // record source info for reconstruction
            std::ostringstream s;
            s << mem.cell->name.str() << " " << mem.start_offset << " " << mem.size << " " << slices;
            block.src().push_back({s.str(), mem.size * slices});

            chain.commit_block();
        }
    }

    void restore_mem_rdport_ffs(std::vector<Mem> &mem_cells, ScanChainBlock &block) {
        SigSpec sdi, sdo;
        sdi = block.data_o();

        for (auto &mem : mem_cells) {
            for (int idx = 0; idx < GetSize(mem.rd_ports); idx++) {
                auto &rd = mem.rd_ports[idx];
                if (rd.clk_enable) {
                    std::string attr;
                    attr = stringf("\\emu_orig_raddr[%d]", idx);
                    if (mem.has_attribute(attr)) {
                        int total_width = GetSize(rd.addr);

                        // reg [..] shadow_raddr;
                        // wire en;
                        // always @(posedge clk) shadow_raddr <= raddr;
                        // assign en = ren && !halt;
                        // assign raddr = en ? input : shadow_raddr;

                        SigSpec shadow_raddr = module->addWire(EMU_NAME(shadow_raddr), total_width);
                        SigSpec en = module->And(NEW_ID, rd.en, module->Not(NEW_ID, wire_halt));
                        SigSpec raddr = module->Mux(NEW_ID, shadow_raddr, rd.addr, en);
                        rd.addr = raddr;

                        for (int i = 0; i < total_width; i += DATA_WIDTH) {
                            int w = total_width - i;
                            if (w > DATA_WIDTH) w = DATA_WIDTH;

                            sdo = sdi;
                            sdi = module->addWire(EMU_NAME(sdi), DATA_WIDTH);

                            module->addDff(NEW_ID, wire_clk,
                                module->Mux(NEW_ID, {Const(0, DATA_WIDTH - w), raddr.extract(i, w)}, sdi, wire_ff_scan), sdo);
                            module->connect(shadow_raddr.extract(i, w), sdo.extract(0, w));

                            block.depth()++;

                            SrcInfo src = mem.get_string_attribute(attr);
                            block.src().push_back({src.extract(i, w), 1});
                        }

                        continue;
                    }

                    attr = stringf("\\emu_orig_rdata[%d]", idx);
                    if (mem.has_attribute(attr)) {
                        int total_width = GetSize(rd.data);

                        // reg [..] shadow_rdata;
                        // reg en;
                        // always @(posedge clk) shadow_rdata <= output;
                        // always @(posedge clk) en <= ren && !halt;
                        // assign output = en ? rdata : shadow_rdata;

                        SigSpec shadow_rdata = module->addWire(EMU_NAME(shadow_rdata), total_width);
                        SigSpec en = module->addWire(EMU_NAME(shadow_rdata_en));
                        SigSpec en_d = module->And(NEW_ID, rd.en, module->Not(NEW_ID, wire_halt));
                        module->addDff(NEW_ID, wire_clk, en_d, en);
                        SigSpec rdata = module->addWire(EMU_NAME(rdata), total_width);
                        SigSpec output = rd.data;
                        module->connect(output, module->Mux(NEW_ID, shadow_rdata, rdata, en));
                        rd.data = rdata;

                        for (int i = 0; i < total_width; i += DATA_WIDTH) {
                            int w = total_width - i;
                            if (w > DATA_WIDTH) w = DATA_WIDTH;

                            sdo = sdi;
                            sdi = module->addWire(EMU_NAME(sdi), DATA_WIDTH);

                            module->addDff(NEW_ID, wire_clk,
                                module->Mux(NEW_ID, {Const(0, DATA_WIDTH - w), output.extract(i, w)}, sdi, wire_ff_scan), sdo);
                            module->connect(shadow_rdata.extract(i, w), sdo.extract(0, w));

                            block.depth()++;

                            SrcInfo src = mem.get_string_attribute(attr);
                            block.src().push_back({src.extract(i, w), 1});
                        }

                        continue;
                    }

                    log_error(
                        "%s.%s: Memory has synchronous read port without source information. \n"
                        "Run emu_opt_ram instead of memory_dff.\n",
                        log_id(module), log_id(mem.cell));
                }
            }
        }
        module->connect(block.data_i(), sdi);
    }

    void generate_mem_last_i(ScanChain &chain) {
        const int cntbits = ceil_log2(chain.depth() + 1);
        // reg [..] cnt;
        // wire full = cnt == chain.depth;
        // always @(posedge clk)
        //   if (!scan)
        //     cnt <= 0;
        //   else if (!full)
        //     cnt <= cnt + 1;
        // wire ok = dir ? full : scan;
        // reg ok_r;
        // always @(posedge clk)
        //    ok_r <= ok;
        // assign last_i = ok && !ok_r;
        SigSpec cnt = module->addWire(EMU_NAME(cnt), cntbits);
        SigSpec full = module->Eq(NEW_ID, cnt, Const(chain.depth(), cntbits));
        module->addSdffe(NEW_ID, wire_clk, module->Not(NEW_ID, full), module->Not(NEW_ID, wire_ram_scan),
            module->Add(NEW_ID, cnt, Const(1, cntbits)), cnt, Const(0, cntbits));
        SigSpec ok = module->Mux(NEW_ID, wire_ram_scan, full, wire_ram_dir);
        SigSpec ok_r = module->addWire(EMU_NAME(ok_r));
        module->addDff(NEW_ID, wire_clk, ok, ok_r);
        module->connect(chain.last_i(), module->And(NEW_ID, ok, module->Not(NEW_ID, ok_r)));
    }

public:

    InsertAccessorWorker(Module *mod) : module(mod), ff_scanchain(0), mem_scanchain(0) {}

    ~InsertAccessorWorker() {
        if (ff_scanchain) delete ff_scanchain;
        if (mem_scanchain) delete mem_scanchain;
    }

    void run() {
        // check if already processed
        if (module->get_bool_attribute("\\emu_instrumented")) {
            log_warning("Module %s is already processed by emu_instrument\n", log_id(module));
            return;
        }

        // RTLIL processes & memories are not accepted
        if (module->has_processes_warn() || module->has_memories_warn())
            log_error("RTLIL processes or memories detected");

        // search for all FFs
        std::vector<Cell *> ff_cells;
        for (auto cell : module->cells())
            if (module->design->selected(module, cell) && RTLIL::builtin_ff_cell_types().count(cell->type))
                if (!cell->get_bool_attribute("\\emu_internal"))
                    ff_cells.push_back(cell);

        // get mem cells
        std::vector<Mem> mem_cells = Mem::get_selected_memories(module);

        // exclude mem cells without write ports (ROM)
        for (auto it = mem_cells.begin(); it != mem_cells.end(); )
            if (it->wr_ports.size() == 0)
                it = mem_cells.erase(it);
            else
                ++it;

        // add accessor ports
        create_ports();

        // find the clock signal
        process_clock(ff_cells, mem_cells);

        ff_scanchain = new ScanChain(module, DATA_WIDTH);
        mem_scanchain = new ScanChain(module, DATA_WIDTH);

        // process FFs
        instrument_ffs(ff_cells, ff_scanchain->new_block());
        ff_scanchain->commit_block();

        // restore merged ffs in read ports
        restore_mem_rdport_ffs(mem_cells, ff_scanchain->new_block());
        ff_scanchain->commit_block();

        // process mems
        instrument_mems(mem_cells, *mem_scanchain);

        module->connect(ff_scanchain->last_i(), State::S0);
        generate_mem_last_i(*mem_scanchain);

        module->connect(ff_scanchain->data_i(), wire_ff_sdi);
        module->connect(wire_ff_sdo, ff_scanchain->data_o());
        module->connect(mem_scanchain->data_i(), wire_ram_sdi);
        module->connect(wire_ram_sdo, mem_scanchain->data_o());

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

        f << "# This file is automatically generated\n"
             "# Syntax:\n"
             "#   SIGCHUNK   := <name> <offset> <width>\n"
             "#   SIGSPEC    := SIGCHUNK [SIGSPEC]\n"
             "#   FF         := <addr> <words> SIGSPEC\n"
             "#   MEM        := <addr> <words> <name> <start_offset> <size> <slices>\n"
             "#   FF_LIST    := FF [FF_LIST]\n"
             "#   MEM_LIST   := MEM [MEM_LIST]\n"
             "#   FF_CHAIN   := chain ff [FF_LIST] <total_words> 0\n"
             "#   MEM_CHAIN  := chain mem [MEM_LIST] <total_words> 0\n"
             "#   CONFIG     := FF_CHAIN MEM_CHAIN\n";

        int id = 0;
        std::vector<const char*> chain_name = {"ff", "mem"};
        for (auto &chain : {ff_scanchain, mem_scanchain}) {
            f << "chain " << chain_name[id++] << "\n";
            int addr = 0;
            for (auto &o : chain->src()) {
                f << addr << " " << o.second << " " << o.first << "\n";
                addr += o.second;
            }
            f << addr << " 0\n";
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

        /*
        f << "`define LOADER_DEFS reg [" << DATA_WIDTH - 1 << ":0] __reconstructed_ffs [" << ff_cells.size() - 1 << ":0];\n";
        f << "`define LOADER_STMTS \\\n";
        f << stringf("    $readmemh({`CHECKPOINT_PATH, \"/ffdata.txt\"}, __reconstructed_ffs);\\\n");
        for (auto &ff : ff_cells) {
            std::string addr = ff->get_string_attribute("\\accessor_addr");
            int new_offset = 0;
            for (auto &s : SrcInfo(ff->get_string_attribute("\\emu_orig")).info) {
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
        */

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

        
        auto modules = design->selected_modules();
        if (modules.size() != 1) {
            log_error(
                "Exactly 1 selected module required.\n"
                "Run flatten first to convert design hierarchy to a flattened module\n");
        }

        auto &mod = modules.front();
        log("Processing module %s\n", mod->name.c_str());
        design->rename(mod, "\\$EMU_DUT");
        InsertAccessorWorker worker(mod);
        worker.run();
        if (!cfg_file.empty()) worker.write_config(cfg_file);
        if (!ldr_file.empty()) worker.write_loader(ldr_file);
    }
} InsertAccessorPass;

PRIVATE_NAMESPACE_END
