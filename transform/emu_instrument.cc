#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"
#include "kernel/utils.h"

#include <queue>

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

// scan chain building block
template <typename T>
struct ScanChainBlock {
    Wire *data_i, *data_o, *last_i, *last_o;
    std::vector<T> src;
    ScanChainBlock() {}
};

// a whole scan chain connecting scan chain blocks
template <typename T>
struct ScanChain : public ScanChainBlock<T> {
    Module *module;
    ScanChainBlock<T> *active_block;

    ScanChain(Module *module, int width) {
        this->module = module;
        this->data_i = this->data_o = module->addWire(NEW_ID, width);
        this->last_i = this->last_o = module->addWire(NEW_ID);
        active_block = 0;
    }

    ~ScanChain() {
        log_assert(active_block == 0);
    }

    ScanChainBlock<T> &new_block() {
        log_assert(active_block == 0);

        active_block = new ScanChainBlock<T>;
        active_block->data_o = this->data_i;
        active_block->last_i = this->last_o;
        active_block->data_i = this->data_i = module->addWire(NEW_ID, this->data_i->width);
        active_block->last_o = this->last_o = module->addWire(NEW_ID);

        return *active_block;
    }

    void commit_block() {
        log_assert(active_block != 0);

        this->src.insert(this->src.end(), active_block->src.begin(), active_block->src.end());

        delete active_block;
        active_block = 0;
    }

};

class InsertAccessorWorker {

private:

    Module *module;
    Database &database;

    Wire *wire_clk;
    Wire *wire_ff_scan, *wire_ff_data_i, *wire_ff_data_o;
    Wire *wire_ram_scan, *wire_ram_dir, *wire_ram_data_i, *wire_ram_data_o, *wire_ram_last_i, *wire_ram_last_o; // dir: 0=out 1=in

    void create_ports() {
        wire_clk        = emu_create_port(module,   PortClk,        1,          false   );
        wire_ff_scan    = emu_create_port(module,   PortFfScanEn,   1,          false   );
        wire_ff_data_i  = emu_create_port(module,   PortFfDataIn,   DATA_WIDTH, false   );
        wire_ff_data_o  = emu_create_port(module,   PortFfDataOut,  DATA_WIDTH, true    );
        wire_ram_scan   = emu_create_port(module,   PortRamScanEn,  1,          false   );
        wire_ram_dir    = emu_create_port(module,   PortRamScanDir, 1,          false   );
        wire_ram_data_i = emu_create_port(module,   PortRamDataIn,  DATA_WIDTH, false   );
        wire_ram_data_o = emu_create_port(module,   PortRamDataOut, DATA_WIDTH, true    );
        wire_ram_last_i = emu_create_port(module,   PortRamLastIn,  1,          false   );
        wire_ram_last_o = emu_create_port(module,   PortRamLastOut, 1,          true    );

        module->fixup_ports();
    }

    void instrument_ffs(std::vector<Cell *> &ff_cells, ScanChainBlock<FfInfo> &block) {

        // process clock, reset, enable signals and insert sdi
        // Original:
        // always @(posedge clk)
        //   if (srst)
        //     q <= SRST_VAL;
        //   else if (ce)
        //     q <= d;
        // Instrumented:
        // always @(posedge gated_clk)
        //   if (srst && !se)
        //     q <= SRST_VAL;
        //   else if (ce || se)
        //     q <= se ? sdi : d;

        std::vector<Cell *> ff_cells_new;
        SigSig sdi_q_list;

        for (auto &cell : ff_cells) {
            FfData ff(nullptr, cell);

            // ignore FFs with emu_no_scachain attribute
            Wire *reg = ff.sig_q.is_wire() ? ff.sig_q.as_wire() : nullptr;
            if (reg && reg->has_attribute(AttrNoScanchain)) {
                log("Ignoring FF %s.%s\n", log_id(module), log_id(reg));
                ff_cells_new.push_back(cell);
                continue;
            }

            if (!ff.pol_srst) {
                ff.sig_srst = module->Not(NEW_ID, ff.sig_srst);
                ff.pol_srst = true;
            }
            ff.sig_srst = module->And(NEW_ID, ff.sig_srst, module->Not(NEW_ID, wire_ff_scan));
            if (!ff.has_ce) {
                ff.sig_ce = State::S1;
                ff.has_ce = true;
                ff.pol_ce = true;
            }
            if (!ff.pol_ce) {
                ff.sig_ce = module->Not(NEW_ID, ff.sig_ce);
                ff.pol_ce = true;
            }

            ff.sig_ce = module->Or(NEW_ID, ff.sig_ce, wire_ff_scan);
            SigSpec sdi = module->addWire(NEW_ID, GetSize(ff.sig_d));
            ff.sig_d = module->Mux(NEW_ID, ff.sig_d, sdi, wire_ff_scan);
            sdi_q_list.first.append(sdi);
            sdi_q_list.second.append(ff.sig_q);
            ff_cells_new.push_back(ff.emit());
        }
        ff_cells.empty();
        ff_cells.insert(ff_cells.begin(), ff_cells_new.begin(), ff_cells_new.end());

        // pad to align data width
        int r = GetSize(sdi_q_list.first) % DATA_WIDTH;
        if (r) {
            int pad = DATA_WIDTH - r;
            Wire *d = module->addWire(NEW_ID, pad);
            Wire *q = module->addWire(NEW_ID, pad);
            module->addDff(NEW_ID, wire_clk, d, q);
            sdi_q_list.first.append(d);
            sdi_q_list.second.append(q);
        }

        // build scan chain
        int size = GetSize(sdi_q_list.first);
        int depth = 0;
        SigSpec sdi, sdo;
        sdi = block.data_o;
        for (int i = 0; i < size; i += DATA_WIDTH) {
            sdo = sdi;
            sdi = sdi_q_list.first.extract(i, DATA_WIDTH);
            SigSpec q = sdi_q_list.second.extract(i, DATA_WIDTH);
            module->connect(sdo, q);
            depth++;
            block.src.push_back(FfInfo(q));
        }
        module->connect(sdi, block.data_i);
    }

    void instrument_mems(std::vector<Mem> &mem_cells, ScanChain<MemInfo> &chain) {
        for (auto &mem : mem_cells) {
            // ignore cells with emu_no_scanchain attribute
            if (mem.has_attribute(AttrNoScanchain)) {
                log("Ignoring memory %s.%s\n", log_id(module), log_id(mem.cell));
                continue;
            }

            auto &block = chain.new_block();

            const int init_addr = mem.start_offset;
            const int last_addr = mem.start_offset + mem.size - 1;
            const int abits = ceil_log2(last_addr);
            const int slices = (mem.width + DATA_WIDTH - 1) / DATA_WIDTH;

            SigSpec inc = module->addWire(NEW_ID);

            // address generator
            // reg [..] addr;
            // wire [..] addr_next = addr + 1;
            // always @(posedge clk)
            //   if (!scan) addr <= 0;
            //   else if (inc) addr <= addr_next;
            SigSpec addr = module->addWire(NEW_ID, abits);
            SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
            module->addSdffe(NEW_ID, wire_clk, inc, module->Not(NEW_ID, wire_ram_scan),
                addr_next, addr, Const(init_addr, abits));

            // assign addr_is_last = addr == last_addr;
            SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(last_addr, abits));

            // shift counter
            // always @(posedge clk)
            //   if (!scan) scnt <= 0;
            //   else scnt <= {scnt[slices-2:0], inc && !addr_is_last};
            SigSpec scnt = module->addWire(NEW_ID, slices);
            module->addSdff(NEW_ID, wire_clk, module->Not(NEW_ID, wire_ram_scan), 
                {scnt.extract(0, slices-1), module->And(NEW_ID, inc, module->Not(NEW_ID, addr_is_last))},
                scnt, Const(0, slices));
            SigSpec scnt_msb = scnt.extract(slices-1);

            // if (mem.size > 1)
            //   assign last_o = scnt[slices-1] && addr_is_last
            // else
            //   assign last_o = last_i
            if (mem.size > 1)
                module->connect(block.last_o, module->And(NEW_ID, scnt_msb, addr_is_last));
            else
                module->connect(block.last_o, block.last_i);

            // assign inc = scnt[slices-1] || last_i;
            module->connect(inc, module->Or(NEW_ID, scnt_msb, block.last_i));

            SigSpec se = module->addWire(NEW_ID);
            SigSpec we = module->addWire(NEW_ID);
            SigSpec rdata = module->addWire(NEW_ID, mem.width);
            SigSpec wdata = module->addWire(NEW_ID, mem.width);

            // create scan chain registers
            SigSpec sdi, sdo;
            sdi = block.data_o;
            for (int i = 0; i < slices; i++) {
                int off = i * DATA_WIDTH;
                int len = mem.width - off;
                if (len > DATA_WIDTH) len = DATA_WIDTH;

                sdo = sdi;
                sdi = module->addWire(NEW_ID, DATA_WIDTH);

                // always @(posedge clk)
                //   r <= se ? sdi : rdata[off+:len];
                // assign sdo = r;
                SigSpec rdata_slice = {Const(0, DATA_WIDTH - len), rdata.extract(off, len)};
                module->addDff(NEW_ID, wire_clk, 
                    module->Mux(NEW_ID, rdata_slice, sdi, se), sdo);
                module->connect(wdata.extract(off, len), sdo.extract(0, len));
            }
            module->connect(block.data_i, sdi);

            // assign se = dir || !inc;
            // assign we = dir && inc;
            module->connect(se, module->Or(NEW_ID, wire_ram_dir, module->Not(NEW_ID, inc)));
            module->connect(we, module->And(NEW_ID, wire_ram_dir, inc));

            // add pause signal to ports
            for (auto &wr : mem.wr_ports) {
                wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), wire_ram_scan);
            }

            // add accessor to write port 0
            auto &wr = mem.wr_ports[0];
            wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), wire_ram_scan);
            if (abits > 0)
                wr.addr = module->Mux(NEW_ID, wr.addr, addr, wire_ram_scan);
            wr.data = module->Mux(NEW_ID, wr.data, wdata, wire_ram_scan);

            // add accessor to read port 0
            auto &rd = mem.rd_ports[0];
            if (abits > 0) {
                // do not use pause signal to select address input here
                // because we need to restore raddr before pause is deasserted to preserve output data
                rd.addr = module->Mux(NEW_ID, rd.addr, module->Mux(NEW_ID, addr, addr_next, inc), wire_ram_scan);
            }
            if (rd.clk_enable) {
                rd.en = module->Or(NEW_ID, rd.en, wire_ram_scan);
                module->connect(rdata, rd.data);
            }
            else {
                // delay 1 cycle for asynchronous read ports
                SigSpec rdata_reg = module->addWire(NEW_ID, mem.width);
                module->addDff(NEW_ID, wire_clk, rd.data, rdata_reg);
                module->connect(rdata, rdata_reg);
            }

            mem.packed = true;
            mem.emit();

            // record source info for reconstruction
            MemInfo info(mem, slices);
            block.src.push_back(info);

            chain.commit_block();
        }
    }

    void add_shadow_rdata(MemRd &rd, FfInfo &src, ScanChainBlock<FfInfo> &block) {
        int total_width = GetSize(rd.data);

        // wire dut_en_r = measure_clk(clk, ram_clk);
        // reg scan_n_r, ren_r;
        // always @(posedge clk) scan_n_r <= !ram_scan;
        // always @(posedge clk) ren_r <= ren;
        // wire run_r = dut_en_r && scan_n_r;
        // wire en = ren_r && run_r;
        // reg [..] shadow_rdata;
        // assign output = en ? rdata : shadow_rdata;
        // always @(posedge clk) begin
        //   if (rst && run_r) shadow_rdata <= RSTVAL;
        //   else if (run_r || ff_scan) shadow_rdata <= ff_scan ? sdi : output;
        // end

        SigSpec dut_en_r = measure_clk(module, wire_clk, rd.clk);

        SigSpec scan_n_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, wire_clk, module->Not(NEW_ID, wire_ram_scan), scan_n_r);
        SigSpec run_r = module->And(NEW_ID, dut_en_r, scan_n_r);

        SigSpec ren_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, wire_clk, rd.en, ren_r);
        SigSpec en = module->And(NEW_ID, ren_r, run_r);

        SigSpec rst = rd.srst;
        if (rd.ce_over_srst)
            rst = module->And(NEW_ID, rst, rd.en);
        rst = module->And(NEW_ID, rst, run_r);

        SigSpec shadow_rdata = module->addWire(NEW_ID, total_width);
        SigSpec rdata = module->addWire(NEW_ID, total_width);
        SigSpec output = rd.data;
        module->connect(output, module->Mux(NEW_ID, shadow_rdata, rdata, en));
        rd.data = rdata;

        SigSig sdi_q_list;
        sdi_q_list.first = module->addWire(NEW_ID, total_width);
        sdi_q_list.second = shadow_rdata;
        module->addSdffe(NEW_ID, wire_clk,
            module->Or(NEW_ID, run_r, wire_ff_scan),
            rst,
            module->Mux(NEW_ID, output, sdi_q_list.first, wire_ff_scan),
            shadow_rdata, rd.srst_value);

        // pad to align data width
        int r = GetSize(sdi_q_list.first) % DATA_WIDTH;
        if (r) {
            int pad = DATA_WIDTH - r;
            Wire *d = module->addWire(NEW_ID, pad);
            Wire *q = module->addWire(NEW_ID, pad);
            module->addDff(NEW_ID, wire_clk, d, q);
            sdi_q_list.first.append(d);
            sdi_q_list.second.append(q);
        }

        // build scan chain
        SigSpec sdi, sdo;
        sdi = block.data_o;
        for (int i = 0; i < total_width; i += DATA_WIDTH) {
            int w = total_width - i;
            if (w > DATA_WIDTH) w = DATA_WIDTH;
            sdo = sdi;
            sdi = sdi_q_list.first.extract(i, DATA_WIDTH);
            SigSpec q = sdi_q_list.second.extract(i, DATA_WIDTH);
            module->connect(sdo, q);
            block.src.push_back(src.extract(i, w));
        }
        module->connect(sdi, block.data_i);
    }

    void restore_mem_rdport_ffs(std::vector<Mem> &mem_cells, ScanChain<FfInfo> &chain_ff) {
        for (auto &mem : mem_cells) {
            for (int idx = 0; idx < GetSize(mem.rd_ports); idx++) {
                auto &rd = mem.rd_ports[idx];
                if (rd.clk_enable) {
                    std::string attr;
                    attr = stringf("\\emu_orig_raddr[%d]", idx);
                    if (mem.has_attribute(attr)) {
                        // synchronous read port inferred by raddr register cannot have reset value, but we still warn on this
                        if (rd.srst != State::S0) {
                            log_warning(
                                "Mem %s.%s should not have a sychronous read port inferred by raddr register with reset\n"
                                "which cannot be emulated correctly. This is possibly a bug in transformation passes.\n",
                                log_id(module), log_id(mem.memid)
                            );
                        }

                        Wire *dummy = module->addWire(NEW_ID, GetSize(rd.data));
                        FfInfo src(dummy);
                        auto &block = chain_ff.new_block();
                        add_shadow_rdata(rd, src, block);
                        chain_ff.commit_block();
                        continue;
                    }

                    attr = stringf("\\emu_orig_rdata[%d]", idx);
                    if (mem.has_attribute(attr)) {
                        FfInfo src = mem.get_string_attribute(attr);
                        auto &block = chain_ff.new_block();
                        add_shadow_rdata(rd, src, block);
                        chain_ff.commit_block();
                        continue;
                    }

                    log_error(
                        "%s.%s: Memory has synchronous read port without source information. \n"
                        "Run emu_opt_ram instead of memory_dff.\n",
                        log_id(module), log_id(mem.cell));
                }
            }
        }
    }

    void instrument_hier_cells(std::vector<Cell *> &hier_cells, ScanChain<FfInfo> &chain_ff, ScanChain<MemInfo> &chain_mem) {
        for (auto &cell : hier_cells) {
            Module *target = module->design->module(cell->type);
            if (!target->get_bool_attribute(AttrInstrumented))
                continue;

            auto &block_ff = chain_ff.new_block();
            auto &block_mem = chain_mem.new_block();

            cell->setPort(emu_get_port_id(target,   PortClk         ),  wire_clk        );
            cell->setPort(emu_get_port_id(target,   PortFfScanEn    ),  wire_ff_scan    );
            cell->setPort(emu_get_port_id(target,   PortFfDataIn    ),  block_ff.data_i );
            cell->setPort(emu_get_port_id(target,   PortFfDataOut   ),  block_ff.data_o );
            cell->setPort(emu_get_port_id(target,   PortRamScanEn   ),  wire_ram_scan   );
            cell->setPort(emu_get_port_id(target,   PortRamScanDir  ),  wire_ram_dir    );
            cell->setPort(emu_get_port_id(target,   PortRamDataIn   ),  block_mem.data_i);
            cell->setPort(emu_get_port_id(target,   PortRamDataOut  ),  block_mem.data_o);
            cell->setPort(emu_get_port_id(target,   PortRamLastIn   ),  block_mem.last_i);
            cell->setPort(emu_get_port_id(target,   PortRamLastOut  ),  block_mem.last_o);

            auto &target_data = database.scanchain.at(cell->type);
            for (auto &src : target_data.ff)
                block_ff.src.push_back(src.nest(cell));
            for (auto &src : target_data.mem)
                block_mem.src.push_back(src.nest(cell));

            chain_ff.commit_block();
            chain_mem.commit_block();
        }
    }

public:

    InsertAccessorWorker(Module *mod, Database &db) : module(mod), database(db) {}

    void run() {
        // check if already processed
        if (module->get_bool_attribute(AttrInstrumented)) {
            log_warning("Module %s is already processed by emu_instrument\n", log_id(module));
            return;
        }

        if (!module->get_bool_attribute(AttrLibProcessed))
            log_error("Module %s is not processed by emu_process_lib. Run emu_process_lib first.\n", log_id(module));

        // search for all FF cells & hierarchical cells
        std::vector<Cell *> ff_cells, hier_cells;
        for (auto cell : module->selected_cells())
            if (RTLIL::builtin_ff_cell_types().count(cell->type))
                ff_cells.push_back(cell);
            else if (module->design->has(cell->type))
                hier_cells.push_back(cell);

        // get mem cells
        std::vector<Mem> mem_cells = Mem::get_selected_memories(module);

        // add submod attribute to mem cells so that each of them is finally in a separate module
        for (auto &mem : mem_cells) {
            std::string name = mem.memid.str();
            mem.set_string_attribute(ID::submod, name[0] == '\\' ? name.substr(1) : name);
            mem.emit();
        }

        // exclude mem cells without write ports (ROM)
        for (auto it = mem_cells.begin(); it != mem_cells.end(); )
            if (it->wr_ports.size() == 0)
                it = mem_cells.erase(it);
            else
                ++it;

        // add accessor ports
        create_ports();

        ScanChain<FfInfo> chain_ff(module, DATA_WIDTH);
        ScanChain<MemInfo> chain_mem(module, DATA_WIDTH);

        // process FFs
        instrument_ffs(ff_cells, chain_ff.new_block());
        chain_ff.commit_block();

        // restore merged ffs in read ports
        restore_mem_rdport_ffs(mem_cells, chain_ff);

        // process mems
        instrument_mems(mem_cells, chain_mem);

        // connect scan chains in hierarchical cells
        instrument_hier_cells(hier_cells, chain_ff, chain_mem);

        module->connect(chain_ff.last_i, State::S0);

        module->connect(chain_ff.data_i, wire_ff_data_i);
        module->connect(wire_ff_data_o, chain_ff.data_o);
        module->connect(chain_mem.data_i, wire_ram_data_i);
        module->connect(wire_ram_data_o, chain_mem.data_o);
        module->connect(chain_mem.last_i, wire_ram_last_i);
        module->connect(wire_ram_last_o, chain_mem.last_o);

        database.scanchain[module->name] = ScanChainData(chain_ff.src, chain_mem.src);

        // set attribute to indicate this module is processed
        module->set_bool_attribute(AttrInstrumented);
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
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_INSTRUMENT pass.\n");

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

        TopoSort<RTLIL::Module*, IdString::compare_ptr_by_name<RTLIL::Module>> topo_modules;
        for (auto &mod : design->selected_modules()) {
            topo_modules.node(mod);
            for (auto &cell : mod->selected_cells()) {
                Module *tpl = design->module(cell->type);
                if (tpl && design->selected_module(tpl)) {
                    topo_modules.edge(tpl, mod);
                }
            }
        }

		if (!topo_modules.sort())
			log_error("Recursive instantiation detected.\n");

        for (auto &mod : topo_modules.sorted) {
            log("Processing module %s\n", mod->name.c_str());
            InsertAccessorWorker worker(mod, db);
            worker.run();
        }
    }
} EmuInstrumentPass;

PRIVATE_NAMESPACE_END
