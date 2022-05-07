#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"
#include "kernel/utils.h"

#include "yaml-cpp/yaml.h"

#include "emu.h"
#include "interface.h"
#include "designtools.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

std::string const2hex(const Const &val) {
    int len = (GetSize(val) + 3) / 4;
    std::string res;
    res.resize(len, ' ');

    for (int i = 0; i < len; i++) {
        int digit = val.extract(i*4, 4).as_int();
        char c;
        if (digit >= 10)
            c = 'a' + digit - 10;
        else
            c = '0' + digit;
        res[len-1-i] = c;
    }

    return res;
}

class InsertAccessorWorker {

    struct ScanChainBuilder {
        DesignHierarchy &hier;

        Wire *clk, *ff_se, *ram_se, *ram_sd;
        Wire *ff_di, *ff_do, *ram_di, *ram_do, *ram_li, *ram_lo;

        void append_ff(Wire *ff_di, Wire *ff_do) {
            hier.connect(this->ff_di, ff_do);
            this->ff_di = ff_di;
        }

        void append_ram(Wire *ram_di, Wire *ram_do, Wire *ram_li, Wire *ram_lo) {
            hier.connect(this->ram_di, ram_do);
            this->ram_di = ram_di;
            hier.connect(ram_li, this->ram_lo);
            this->ram_lo = ram_lo;
        }

        Wire *get_clk(Module *module) {
            Wire *wire = module->addWire(NEW_ID);
            hier.connect(wire, clk);
            return wire;
        }

        Wire *get_ff_se(Module *module) {
            Wire *wire = module->addWire(NEW_ID);
            hier.connect(wire, ff_se);
            return wire;
        }

        Wire *get_ram_se(Module *module) {
            Wire *wire = module->addWire(NEW_ID);
            hier.connect(wire, ram_se);
            return wire;
        }

        Wire *get_ram_sd(Module *module) {
            Wire *wire = module->addWire(NEW_ID);
            hier.connect(wire, ram_sd);
            return wire;
        }

        ScanChainBuilder(DesignHierarchy &hier, int ff_width, int ram_width, 
                         Wire *clk, Wire *ff_se, Wire *ram_se, Wire *ram_sd)
            : hier(hier), clk(clk), ff_se(ff_se), ram_se(ram_se), ram_sd(ram_sd)
        {
            ff_di  = ff_do  = hier.top->addWire(NEW_ID, ff_width);
            ram_di = ram_do = hier.top->addWire(NEW_ID, ram_width);
            ram_li = ram_lo = hier.top->addWire(NEW_ID);
        }
    };

    Design *design;
    DesignHierarchy hier;
    int ff_width, ram_width;

    std::vector<FfInfo> ff_list;
    std::vector<MemInfo> ram_list;

    void instrument_ffs(Module *module, ScanChainBuilder &builder, std::vector<Cell *> &ff_cells) {

        auto path = hier.scope_of(module);

        Wire *clk   = builder.get_clk(module);
        Wire *ff_se = builder.get_ff_se(module);

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

        SigMap sigmap;
        FfInitVals initvals;
        sigmap.set(module);
        initvals.set(&sigmap, module);

        for (auto &cell : ff_cells) {
            FfData ff(&initvals, cell);

            // ignore cells whose clock is not rewritten
            if (!cell->get_bool_attribute(AttrClkRewritten)) {
                if (ff.sig_q.is_wire())
                    log("Ignoring FF %s.%s\n", log_id(module), log_id(ff.sig_q.as_wire()));
                else
                    for (auto &bit : ff.sig_q)
                        if (bit.is_wire())
                            log("Ignoring FF %s.%s[%d]\n",
                                log_id(module), log_id(bit.wire), bit.offset);
                ff_cells_new.push_back(cell);
                continue;
            }

            if (!ff.pol_srst) {
                ff.sig_srst = module->Not(NEW_ID, ff.sig_srst);
                ff.pol_srst = true;
            }
            ff.sig_srst = module->And(NEW_ID, ff.sig_srst, module->Not(NEW_ID, ff_se));
            if (!ff.has_ce) {
                ff.sig_ce = State::S1;
                ff.has_ce = true;
                ff.pol_ce = true;
            }
            if (!ff.pol_ce) {
                ff.sig_ce = module->Not(NEW_ID, ff.sig_ce);
                ff.pol_ce = true;
            }

            ff.sig_ce = module->Or(NEW_ID, ff.sig_ce, ff_se);
            SigSpec sdi = module->addWire(NEW_ID, GetSize(ff.sig_d));
            ff.sig_d = module->Mux(NEW_ID, ff.sig_d, sdi, ff_se);
            sdi_q_list.first.append(sdi);
            sdi_q_list.second.append(ff.sig_q);
            ff_cells_new.push_back(ff.emit());
        }
        ff_cells.empty();
        ff_cells.insert(ff_cells.begin(), ff_cells_new.begin(), ff_cells_new.end());

        // pad to align data width
        int r = GetSize(sdi_q_list.first) % ff_width;
        if (r) {
            int pad = ff_width - r;
            Wire *d = module->addWire(NEW_ID, pad);
            Wire *q = module->addWire(NEW_ID, pad);
            module->addDff(NEW_ID, clk, d, q);
            sdi_q_list.first.append(d);
            sdi_q_list.second.append(q);
        }

        // build scan chain
        int size = GetSize(sdi_q_list.first);
        for (int i = 0; i < size; i += ff_width) {
            SigSpec sdi = sdi_q_list.first.extract(i, ff_width);
            SigSpec q = sdi_q_list.second.extract(i, ff_width);
            Wire *ff_di = module->addWire(NEW_ID, ff_width);
            Wire *ff_do = module->addWire(NEW_ID, ff_width);
            module->connect(sdi, ff_di);
            module->connect(ff_do, q);
            builder.append_ff(ff_di, ff_do);
            ff_list.push_back(FfInfo(q, initvals(q), path));
        }
    }

    void instrument_mems(Module *module, ScanChainBuilder &builder, std::vector<Mem> &mem_cells) {

        auto path = hier.scope_of(module);

        Wire *clk       = builder.get_clk(module);
        Wire *ram_se    = builder.get_ram_se(module);
        Wire *ram_sd    = builder.get_ram_sd(module);

        for (auto &mem : mem_cells) {

            Wire *ram_di = module->addWire(NEW_ID, ram_width);
            Wire *ram_do = module->addWire(NEW_ID, ram_width);
            Wire *ram_li = module->addWire(NEW_ID);
            Wire *ram_lo = module->addWire(NEW_ID);

            // ignore cells whose clock is not rewritten
            if (!mem.get_bool_attribute(AttrClkRewritten)) {
                log("Ignoring memory %s.%s\n", log_id(module), log_id(mem.cell));
                continue;
            }

            const int init_addr = mem.start_offset;
            const int last_addr = mem.start_offset + mem.size - 1;
            const int abits = ceil_log2(last_addr);
            const int slices = (mem.width + ram_width - 1) / ram_width;

            SigSpec inc = module->addWire(NEW_ID);

            // address generator
            // reg [..] addr;
            // wire [..] addr_next = addr + 1;
            // always @(posedge clk)
            //   if (!scan) addr <= 0;
            //   else if (inc) addr <= addr_next;
            SigSpec addr = module->addWire(NEW_ID, abits);
            SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
            module->addSdffe(NEW_ID, clk, inc, module->Not(NEW_ID, ram_se),
                addr_next, addr, Const(init_addr, abits));

            // assign addr_is_last = addr == last_addr;
            SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(last_addr, abits));

            // shift counter
            // always @(posedge clk)
            //   if (!scan) scnt <= 0;
            //   else scnt <= {scnt[slices-2:0], inc && !addr_is_last};
            SigSpec scnt = module->addWire(NEW_ID, slices);
            module->addSdff(NEW_ID, clk, module->Not(NEW_ID, ram_se), 
                {scnt.extract(0, slices-1), module->And(NEW_ID, inc, module->Not(NEW_ID, addr_is_last))},
                scnt, Const(0, slices));
            SigSpec scnt_msb = scnt.extract(slices-1);

            // if (mem.size > 1)
            //   assign last_o = scnt[slices-1] && addr_is_last
            // else
            //   assign last_o = last_i
            if (mem.size > 1)
                module->connect(ram_lo, module->And(NEW_ID, scnt_msb, addr_is_last));
            else
                module->connect(ram_lo, ram_li);

            // assign inc = scnt[slices-1] || last_i;
            module->connect(inc, module->Or(NEW_ID, scnt_msb, ram_li));

            SigSpec se = module->addWire(NEW_ID);
            SigSpec we = module->addWire(NEW_ID);
            SigSpec rdata = module->addWire(NEW_ID, mem.width);
            SigSpec wdata = module->addWire(NEW_ID, mem.width);

            // create scan chain registers
            SigSpec sdi, sdo;
            sdi = ram_do;
            for (int i = 0; i < slices; i++) {
                int off = i * ram_width;
                int len = mem.width - off;
                if (len > ram_width) len = ram_width;

                sdo = sdi;
                sdi = module->addWire(NEW_ID, ram_width);

                // always @(posedge clk)
                //   r <= se ? sdi : rdata[off+:len];
                // assign sdo = r;
                SigSpec rdata_slice = {Const(0, ram_width - len), rdata.extract(off, len)};
                module->addDff(NEW_ID, clk, 
                    module->Mux(NEW_ID, rdata_slice, sdi, se), sdo);
                module->connect(wdata.extract(off, len), sdo.extract(0, len));
            }
            module->connect(ram_di, sdi);

            // assign se = dir || !inc;
            // assign we = dir && inc;
            module->connect(se, module->Or(NEW_ID, ram_sd, module->Not(NEW_ID, inc)));
            module->connect(we, module->And(NEW_ID, ram_sd, inc));

            for (auto &wr : mem.wr_ports) {
                // add pause signal to ports
                wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), ram_se);
                // fix up addr width
                wr.addr.extend_u0(abits);
            }

            // add accessor to write port 0
            auto &wr = mem.wr_ports[0];
            wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), ram_se);
            if (abits > 0)
                wr.addr = module->Mux(NEW_ID, wr.addr, addr, ram_se);
            wr.data = module->Mux(NEW_ID, wr.data, wdata, ram_se);

            for (auto &rd : mem.rd_ports) {
                // fix up addr width
                rd.addr.extend_u0(abits);
            }

            // add accessor to read port 0
            auto &rd = mem.rd_ports[0];
            if (abits > 0) {
                // do not use pause signal to select address input here
                // because we need to restore raddr before pause is deasserted to preserve output data
                rd.addr = module->Mux(NEW_ID, rd.addr, module->Mux(NEW_ID, addr, addr_next, inc), ram_se);
            }
            if (rd.clk_enable) {
                rd.en = module->Or(NEW_ID, rd.en, ram_se);
                module->connect(rdata, rd.data);
            }
            else {
                // delay 1 cycle for asynchronous read ports
                SigSpec rdata_reg = module->addWire(NEW_ID, mem.width);
                module->addDff(NEW_ID, clk, rd.data, rdata_reg);
                module->connect(rdata, rdata_reg);
            }

            mem.packed = true;
            mem.emit();

            builder.append_ram(ram_di, ram_do, ram_li, ram_lo);

            // record source info for reconstruction
            MemInfo info(mem, slices, path);
            ram_list.push_back(info);
        }
    }

    void add_shadow_rdata(Module *module, ScanChainBuilder &builder, MemRd &rd, FfInfo &src) {

        Wire *clk       = builder.get_clk(module);
        Wire *ff_se     = builder.get_ff_se(module);
        Wire *ram_se    = builder.get_ram_se(module);

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

        SigSpec dut_en_r = measure_clk(module, clk, rd.clk);

        SigSpec scan_n_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, clk, module->Not(NEW_ID, ram_se), scan_n_r);
        SigSpec run_r = module->And(NEW_ID, dut_en_r, scan_n_r);

        SigSpec ren_r = module->addWire(NEW_ID);
        module->addDff(NEW_ID, clk, rd.en, ren_r);
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
        module->addSdffe(NEW_ID, clk,
            module->Or(NEW_ID, run_r, ff_se),
            rst,
            module->Mux(NEW_ID, output, sdi_q_list.first, ff_se),
            shadow_rdata, rd.srst_value);

        // pad to align data width
        int r = GetSize(sdi_q_list.first) % ff_width;
        if (r) {
            int pad = ff_width - r;
            Wire *d = module->addWire(NEW_ID, pad);
            Wire *q = module->addWire(NEW_ID, pad);
            module->addDff(NEW_ID, clk, d, q);
            sdi_q_list.first.append(d);
            sdi_q_list.second.append(q);
        }

        // build scan chain
        for (int i = 0; i < total_width; i += ff_width) {
            int w = total_width - i;
            if (w > ff_width) w = ff_width;
            SigSpec sdi = sdi_q_list.first.extract(i, ff_width);
            SigSpec q = sdi_q_list.second.extract(i, ff_width);
            Wire *ff_di = module->addWire(NEW_ID, ff_width);
            Wire *ff_do = module->addWire(NEW_ID, ff_width);
            module->connect(sdi, ff_di);
            module->connect(ff_do, q);
            builder.append_ff(ff_di, ff_do);
            ff_list.push_back(src.extract(i, w));
        }
    }

    void restore_mem_rdport_ffs(Module *module, ScanChainBuilder &builder, std::vector<Mem> &mem_cells) {

        auto path = hier.scope_of(module);

        for (auto &mem : mem_cells) {
            // ignore cells whose clock is not rewritten
            if (!mem.get_bool_attribute(AttrClkRewritten))
                continue;

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
                        FfInfo src(dummy, Const(0, GetSize(rd.data)), path);
                        add_shadow_rdata(module, builder, rd, src);
                        continue;
                    }

                    attr = stringf("\\emu_orig_rdata[%d]", idx);
                    if (mem.has_attribute(attr)) {
                        FfInfo src(mem.get_string_attribute(attr), path);
                        add_shadow_rdata(module, builder, rd, src);
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

    void process_module(Module *module, ScanChainBuilder &builder) {

        // search for all FF cells & hierarchical cells
        std::vector<Cell *> ff_cells, hier_cells;
        for (auto cell : module->cells())
            if (RTLIL::builtin_ff_cell_types().count(cell->type))
                ff_cells.push_back(cell);
            else if (module->design->has(cell->type))
                hier_cells.push_back(cell);

        // get mem cells
        std::vector<Mem> mem_cells = Mem::get_all_memories(module);

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

        // process FFs
        instrument_ffs(module, builder, ff_cells);

        // restore merged ffs in read ports
        restore_mem_rdport_ffs(module, builder, mem_cells);

        // process mems
        instrument_mems(module, builder, mem_cells);

    }

public:

    InsertAccessorWorker(Design *design, int ff_width, int ram_width)
        : design(design), hier(design), ff_width(ff_width), ram_width(ram_width) {}

    void run() {

        // Add scan chain ports to top module

        Wire *clk       = create_intf_port(hier.top,    "host_clk", 1           );
        Wire *ff_se     = create_intf_port(hier.top,    "ff_se",    1           );
        Wire *ff_di     = create_intf_port(hier.top,    "ff_di",    ff_width    );
        Wire *ff_do     = create_intf_port(hier.top,    "ff_do",    ff_width    );
        Wire *ram_se    = create_intf_port(hier.top,    "ram_se",   1           );
        Wire *ram_sd    = create_intf_port(hier.top,    "ram_sd",   1           ); // dir: 0=out 1=in
        Wire *ram_di    = create_intf_port(hier.top,    "ram_di",   ram_width   );
        Wire *ram_do    = create_intf_port(hier.top,    "ram_do",   ram_width   );

        hier.top->fixup_ports();

        // Process modules

        ScanChainBuilder builder(hier, ff_width, ram_width, clk, ff_se, ram_se, ram_sd);

        for (Module *module : design->modules()) {
            log("Processing module %s\n", log_id(module));
            process_module(module, builder);
        }

        // Tie off scan chain connections

        hier.connect(builder.ff_di, ff_di);
        hier.connect(ff_do, builder.ff_do);
        hier.connect(builder.ram_di, ram_di);
        hier.connect(ram_do, builder.ram_do);

        int sc_depth = 0;
        for (auto &m : ram_list)
            sc_depth += m.slices;

        generate_mem_last_i(hier.top, sc_depth, clk, ram_se, ram_sd, builder.ram_li);

        // Save FF & RAM word counts

        hier.top->attributes["\\emu_sc_ff_count"] = Const(GetSize(ff_list));

        int words = 0;
        for (auto &mem : ram_list)
            words += mem.depth;

        hier.top->attributes["\\emu_sc_ram_count"] = Const(words);

    }

    void write_init(std::string init_file) {
        std::ofstream f;

        f.open(init_file.c_str(), std::ofstream::binary);
        if (f.fail()) {
            log_error("Can't open file `%s' for writing: %s\n", init_file.c_str(), strerror(errno));
        }

        log("Writing to file `%s'\n", init_file.c_str());

        for (auto &src : ff_list) {
            f << const2hex(src.initval) << "\n";
        }

        for (auto &mem : ram_list) {
            for (int i = 0; i < mem.mem_depth; i++) {
                Const word = mem.init_data.extract(i * mem.mem_width, mem.mem_width);
                for (int j = 0; j < mem.mem_width; j += ram_width)
                    f << const2hex(word.extract(j, ram_width)) << "\n";
            }
        }

        f.close();
    }

    void write_yaml(std::string yaml_file) {
        std::ofstream f;

        f.open(yaml_file.c_str(), std::ofstream::trunc);
        if (f.fail()) {
            log_error("Can't open file `%s' for writing: %s\n", yaml_file.c_str(), strerror(errno));
        }

        log("Writing to file `%s'\n", yaml_file.c_str());

        YAML::Node node;

        node["ff_width"]  = ff_width;
        node["mem_width"] = ram_width;

        node["ff"] = YAML::Node(YAML::NodeType::Sequence);
        for (auto &src : ff_list) {
            YAML::Node ff_node;
            for (auto &c : src.info) {
                YAML::Node src_node;
                src_node["name"] = c.is_public ? simple_hier_name(c.name) : "";
                src_node["offset"] = c.offset;
                src_node["width"] = c.width;
                ff_node.push_back(src_node);
            }
            node["ff"].push_back(ff_node);
        }

        node["mem"] = YAML::Node(YAML::NodeType::Sequence);
        for (auto &mem : ram_list) {
            YAML::Node mem_node;
            mem_node["name"] = simple_hier_name(mem.name);
            mem_node["width"] = mem.mem_width;
            mem_node["depth"] = mem.mem_depth;
            mem_node["start_offset"] = mem.mem_start_offset;
            node["mem"].push_back(mem_node);
        }

        f << node;
        f.close();
    }

    void write_loader(std::string loader_file) {
        std::ofstream os;

        os.open(loader_file.c_str(), std::ofstream::trunc);
        if (os.fail()) {
            log_error("Can't open file `%s' for writing: %s\n", loader_file.c_str(), strerror(errno));
        }

        log("Writing to file `%s'\n", loader_file.c_str());

        int addr;

        os << "`define LOAD_DECLARE integer __load_i;\n";
        os << "`define LOAD_FF_WIDTH " << ff_width << "\n";
        os << "`define LOAD_MEM_WIDTH " << ram_width << "\n";

        os << "`define LOAD_FF(__LOAD_FF_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
        addr = 0;
        for (auto &src : ff_list) {
            int offset = 0;
            for (auto info : src.info) {
                if (!info.is_public)
                    continue;
                info.name.erase(info.name.begin()); // remove top name
                std::string name = simple_hier_name(info.name);
                os  << "    __LOAD_DUT." << name
                    << "[" << info.width + info.offset - 1 << ":" << info.offset << "] = __LOAD_FF_DATA[__LOAD_OFFSET+" << addr << "]"
                    << "[" << info.width + offset - 1 << ":" << offset << "]; \\\n";
                offset += info.width;
            }
            addr++;
        }
        os << "\n";
        os << "`define CHAIN_FF_WORDS " << addr << "\n";

        os << "`define LOAD_MEM(__LOAD_MEM_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
        addr = 0;
        for (auto &mem : ram_list) {
            if (!mem.is_public)
                continue;
            mem.name.erase(mem.name.begin()); // remove top name
            std::string name = simple_hier_name(mem.name);
            os  << "    for (__load_i=0; __load_i<" << mem.mem_depth << "; __load_i=__load_i+1) __LOAD_DUT."
                << name << "[__load_i+" << mem.mem_start_offset << "] = {";
            for (int i = mem.slices - 1; i >= 0; i--)
                os << "__LOAD_MEM_DATA[__LOAD_OFFSET+__load_i*" << mem.slices << "+" << addr + i << "]" << (i != 0 ? ", " : "");
            os << "}; \\\n";
            addr += mem.depth;
        }
        os << "\n";
        os << "`define CHAIN_MEM_WORDS " << addr << "\n";

        os.close();
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
        log("    -ff_width <width>\n");
        log("        specify the width of FF scan chain (default=64)\n");
        log("    -ram_width <width>\n");
        log("        specify the width of RAM scan chain (default=64)\n");
        log("    -init <file>\n");
        log("        write initial scan chain data to the specified file\n");
        log("    -yaml <file>\n");
        log("        write generated yaml configuration to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_INSTRUMENT pass.\n");

        std::string init_file, yaml_file, loader_file;
        int ff_width = 64, ram_width = 64;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-ff_width" && argidx+1 < args.size()) {
                ff_width = std::stoi(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-ram_width" && argidx+1 < args.size()) {
                ram_width = std::stoi(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-init" && argidx+1 < args.size()) {
                init_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-yaml" && argidx+1 < args.size()) {
                yaml_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-loader" && argidx+1 < args.size()) {
                loader_file = args[++argidx];
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        InsertAccessorWorker worker(design, ff_width, ram_width);
        worker.run();

        if (!init_file.empty())
            worker.write_init(init_file);

        if (!yaml_file.empty())
            worker.write_yaml(yaml_file);

        if (!loader_file.empty())
            worker.write_loader(loader_file);
    }
} EmuInstrumentPass;

PRIVATE_NAMESPACE_END
