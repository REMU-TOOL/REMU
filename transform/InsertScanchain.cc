#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"
#include "kernel/utils.h"

#include "attr.h"
#include "transform.h"
#include "database.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct FfChainBuilder {
    EmulationRewriter &rewriter;
    HierconnBuilder hierconn;
    FfMemInfoExtractor extractor;

    int ff_width;

    Wire *ff_di, *ff_do;

    SigSpec sdi_list;
    SigSpec q_list;
    SigSpec info_q_list;
    SigSpec init_list;

    void append_ff(const SigSpec &sdi, const SigSpec &q, const SigSpec &info_q, const Const &init)
    {
        log_assert(GetSize(sdi) == GetSize(q));
        log_assert(GetSize(sdi) == GetSize(info_q));
        log_assert(GetSize(sdi) == GetSize(init));

        sdi_list.append(sdi);
        q_list.append(q);
        info_q_list.append(info_q);
        init_list.append(init);
    }

    void build()
    {
        Module *target = rewriter.target();

        // pad to align data width
        int r = GetSize(sdi_list) % ff_width;
        if (r) {
            int pad = ff_width - r;
            Wire *d = target->addWire(target->uniquify("\\pad_d"), pad);
            Wire *q = target->addWire(target->uniquify("\\pad_q"), pad);
            Wire *host_clk = rewriter.wire("host_clk")->get(target);
            Wire *ff_se = rewriter.wire("ff_se")->get(target);
            target->addDffe(NEW_ID, host_clk, ff_se, d, q);
            sdi_list.append(d);
            q_list.append(q);
            info_q_list.append(q);
            init_list.append(Const(0, pad));
        }

        // build scan chain
        int size = GetSize(sdi_list);
        SigSpec prev_q = ff_di;
        for (int i = 0; i < size; i += ff_width) {
            SigSpec sdi = sdi_list.extract(i, ff_width);
            SigSpec q = q_list.extract(i, ff_width);
            SigSpec info_q = info_q_list.extract(i, ff_width);
            Const init = init_list.extract(i, ff_width).as_const();
            hierconn.connect(sdi, prev_q);
            prev_q = q;
            extractor.add_ff(info_q, init);
        }
        hierconn.connect(ff_do, prev_q);
    }

    FfChainBuilder(EmulationRewriter &rewriter, EmulationDatabase &database, int ff_width)
        : rewriter(rewriter), hierconn(rewriter.design()),
        extractor(rewriter.design(), rewriter.target(), database), ff_width(ff_width)
    {
        Module *wrapper = rewriter.wrapper();
        ff_di = wrapper->addWire(wrapper->uniquify("\\ff_di"), ff_width);
        ff_do = wrapper->addWire(wrapper->uniquify("\\ff_do"), ff_width);
    }
};

struct MemChainBuilder {
    EmulationRewriter &rewriter;
    HierconnBuilder hierconn;

    Wire *ram_di, *ram_do, *ram_li, *ram_lo;

    void append_ram(Wire *ram_di, Wire *ram_do, Wire *ram_li, Wire *ram_lo) {
        hierconn.connect(this->ram_di, ram_do);
        this->ram_di = ram_di;
        hierconn.connect(ram_li, this->ram_lo);
        this->ram_lo = ram_lo;
    }

    MemChainBuilder(EmulationRewriter &rewriter, int ram_width)
        : rewriter(rewriter), hierconn(rewriter.design())
    {
        Module *wrapper = rewriter.wrapper();
        ram_di = ram_do = wrapper->addWire(wrapper->uniquify("\\ram_di_do"), ram_width);
        ram_li = ram_lo = wrapper->addWire(wrapper->uniquify("\\ram_li_lo"));
    }
};

struct ScanchainWorker {

    EmulationRewriter &rewriter;
    DesignHierarchy &designinfo;
    EmulationDatabase &database;
    FfMemInfoExtractor extractor;

    int ff_width, ram_width;

    void instrument_ffs(Module *module, FfChainBuilder &ff_builder);
    void instrument_mems(Module *module, MemChainBuilder &mem_builder);
    void restore_mem_rdport_ffs(Module *module, FfChainBuilder &ff_builder);

public:

    ScanchainWorker(EmulationDatabase &database, EmulationRewriter &rewriter) :
        rewriter(rewriter), designinfo(rewriter.design()), database(database),
        extractor(designinfo, rewriter.target(), database)
    {
        ff_width = rewriter.wire("ff_di")->width();
        ram_width = rewriter.wire("ram_di")->width();
    }

    void run();
    void report_ff();
    void report_mem();

};

void ScanchainWorker::instrument_ffs(Module *module, FfChainBuilder &ff_builder)
{
    Wire *scan_mode = rewriter.wire("scan_mode")->get(module);

    // process clock, reset, enable signals and insert sdi
    // Original:
    // always @(posedge clk)
    //   if (srst)
    //     q <= SRST_VAL;
    //   else if (ce)
    //     q <= d;
    // Instrumented:
    // always @(posedge gated_clk)
    //   if (srst && !scan_mode)
    //     q <= SRST_VAL;
    //   else if (ce || scan_mode)
    //     q <= scan_mode ? sdi : d;

    SigSpec sdi_list, q_list;

    SigMap sigmap;
    FfInitVals initvals;
    sigmap.set(module);
    initvals.set(&sigmap, module);

    for (auto cell : module->cells().to_vector()) {
        if (RTLIL::builtin_ff_cell_types().count(cell->type) == 0)
            continue;

        FfData ff(&initvals, cell);
        pool<int> removed_bits;

        int offset = 0;
        for (auto chunk : ff.sig_q.chunks()) {
            if (chunk.is_wire()) {
                if (designinfo.check_hier_attr(Attr::NoScanchain, chunk.wire)) {
                    log("Ignoring ff cell %s\n",
                        designinfo.flat_name_of(chunk).c_str());

                    std::vector<int> bits;
                    for (int i = offset; i < offset + chunk.size(); i++) {
                        bits.push_back(i);
                        removed_bits.insert(i);
                    }
                    FfData ignored_ff = ff.slice(bits);
                    ignored_ff.emit();
                }
                else {
                    log("Rewriting ff cell %s\n",
                        designinfo.flat_name_of(chunk).c_str());
                }
            }
            offset += chunk.size();
        }

        std::vector<int> bits;
        for (int i = 0; i < ff.width; i++)
            if (removed_bits.count(i) == 0)
                bits.push_back(i);
        ff = ff.slice(bits);
        ff.cell = cell;

        if (!ff.pol_srst) {
            ff.sig_srst = module->Not(NEW_ID, ff.sig_srst);
            ff.pol_srst = true;
        }
        ff.sig_srst = module->And(NEW_ID, ff.sig_srst, module->Not(NEW_ID, scan_mode));
        if (!ff.has_ce) {
            ff.sig_ce = State::S1;
            ff.has_ce = true;
            ff.pol_ce = true;
        }
        if (!ff.pol_ce) {
            ff.sig_ce = module->Not(NEW_ID, ff.sig_ce);
            ff.pol_ce = true;
        }

        ff.sig_ce = module->Or(NEW_ID, ff.sig_ce, scan_mode);
        SigSpec sdi = module->addWire(module->uniquify("\\sdi"), GetSize(ff.sig_d));
        ff.sig_d = module->Mux(NEW_ID, ff.sig_d, sdi, scan_mode);
        sdi_list.append(sdi);
        q_list.append(ff.sig_q);
        ff.emit();
    }

    ff_builder.append_ff(sdi_list, q_list, q_list, initvals(q_list));
}

void ScanchainWorker::instrument_mems(Module *module, MemChainBuilder &mem_builder)
{
    Wire *host_clk  = rewriter.wire("host_clk")->get(module);
    Wire *scan_mode = rewriter.wire("scan_mode")->get(module);
    Wire *ram_sr    = rewriter.wire("ram_sr")->get(module);
    Wire *ram_se    = rewriter.wire("ram_se")->get(module);
    Wire *ram_sd    = rewriter.wire("ram_sd")->get(module);

    for (auto &mem : Mem::get_all_memories(module)) {

        // add submod attribute to mem cells so that each of them is finally in a separate module
        std::string name = mem.memid.str();
        mem.set_string_attribute(ID::submod, name[0] == '\\' ? name.substr(1) : name);

        // exclude mem cells without write ports (ROM)
        if (mem.wr_ports.size() == 0) {
            log("Ignoring ROM %s\n",
                designinfo.flat_name_of(mem.cell).c_str());
            continue;
        }

        if (designinfo.check_hier_attr(Attr::NoScanchain, mem.cell)) {
            log("Ignoring mem cell %s\n",
                designinfo.flat_name_of(mem.cell).c_str());
            continue;
        }

        Wire *ram_di = module->addWire(module->uniquify("\\ram_di"), ram_width);
        Wire *ram_do = module->addWire(module->uniquify("\\ram_do"), ram_width);
        Wire *ram_li = module->addWire(module->uniquify("\\ram_li"));
        Wire *ram_lo = module->addWire(module->uniquify("\\ram_lo"));

        log("Rewriting mem cell %s\n",
            designinfo.flat_name_of(mem.cell).c_str());

        const int abits = ceil_log2(mem.size);
        const int slices = (mem.width + ram_width - 1) / ram_width;

        SigSpec inc = module->addWire(module->uniquify(name + "_inc"));

        // address generator
        // reg [..] addr;
        // wire [..] addr_next = addr + 1;
        // always @(posedge host_clk)
        //   if (ram_sr) addr <= 0;
        //   else if (ram_se && inc) addr <= addr_next;
        SigSpec addr = module->addWire(module->uniquify(name + "_addr"), abits);
        SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
        module->addSdffe(NEW_ID, host_clk, module->And(NEW_ID, ram_se, inc), ram_sr,
            addr_next, addr, Const(0, abits));

        // assign addr_is_last = addr == mem.size - 1;
        SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(mem.size - 1, abits));

        // shift counter
        // always @(posedge host_clk)
        //   if (ram_sr) scnt <= 0;
        //   else if (ram_se) scnt <= {scnt[slices-2:0], inc && !addr_is_last};
        SigSpec scnt = module->addWire(module->uniquify(name + "_scnt"), slices);
        module->addSdffe(NEW_ID, host_clk, ram_se, ram_sr, 
            {scnt.extract(0, slices-1), module->And(NEW_ID, inc, module->Not(NEW_ID, addr_is_last))},
            scnt, Const(0, slices));
        SigSpec scnt_msb = scnt.extract(slices-1);

        // if (mem.size > 1)
        //   assign ram_lo = scnt[slices-1] && addr_is_last
        // else
        //   assign ram_lo = ram_li
        if (mem.size > 1)
            module->connect(ram_lo, module->And(NEW_ID, scnt_msb, addr_is_last));
        else
            module->connect(ram_lo, ram_li);

        // assign inc = scnt[slices-1] || ram_li;
        module->connect(inc, module->Or(NEW_ID, scnt_msb, ram_li));

        SigSpec se = module->addWire(module->uniquify(name + "_se"));
        SigSpec we = module->addWire(module->uniquify(name + "_we"));
        SigSpec rdata = module->addWire(module->uniquify(name + "_rdata"), mem.width);
        SigSpec wdata = module->addWire(module->uniquify(name + "_wdata"), mem.width);

        // assign se = ram_sd || !inc;
        // assign we = ram_sd && inc;
        module->connect(se, module->Or(NEW_ID, ram_sd, module->Not(NEW_ID, inc)));
        module->connect(we, module->And(NEW_ID, ram_sd, inc));

        int extended_addr_len = abits > 32 ? abits : 32;

        for (auto &wr : mem.wr_ports) {
            // add pause signal to ports
            wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), scan_mode);
            // fix up addr width
            wr.addr.extend_u0(extended_addr_len);
        }

        // add accessor to write port 0
        auto &wr = mem.wr_ports[0];
        wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), scan_mode);
        SigSpec scan_waddr = addr;
        scan_waddr.extend_u0(extended_addr_len);
        scan_waddr = module->Add(NEW_ID, scan_waddr, Const(mem.start_offset, extended_addr_len));
        wr.addr = module->Mux(NEW_ID, wr.addr, scan_waddr, scan_mode);
        wr.data = module->Mux(NEW_ID, wr.data, wdata, scan_mode);

        for (auto &rd : mem.rd_ports) {
            // mask reset in scan mode
            if (rd.clk_enable)
                rd.srst = module->And(NEW_ID, rd.srst, module->Not(NEW_ID, scan_mode));
            // fix up addr width
            rd.addr.extend_u0(extended_addr_len);
        }

        // add accessor to read port 0
        auto &rd = mem.rd_ports[0];
        SigSpec scan_raddr = module->Mux(NEW_ID, addr, addr_next, inc);
        scan_raddr.extend_u0(extended_addr_len);
        scan_raddr = module->Add(NEW_ID, scan_raddr, Const(mem.start_offset, extended_addr_len));
        rd.addr = module->Mux(NEW_ID, rd.addr, scan_raddr, scan_mode);
        if (rd.clk_enable) {
            rd.en = module->Or(NEW_ID, rd.en, scan_mode);
            module->connect(rdata, rd.data);
        }
        else {
            // delay 1 cycle for asynchronous read ports
            SigSpec rdata_reg = module->addWire(module->uniquify(name + "_rdata_reg"), mem.width);
            module->addDffe(NEW_ID, host_clk, ram_se, rd.data, rdata_reg);
            module->connect(rdata, rdata_reg);
        }

        // create scan chain registers
        SigSpec sdi, sdo;
        sdi = ram_do;
        for (int i = 0; i < slices; i++) {
            int off = i * ram_width;
            int len = mem.width - off;
            if (len > ram_width) len = ram_width;

            sdo = sdi;
            sdi = module->addWire(module->uniquify(name + "_sdi"), ram_width);

            // always @(posedge host_clk)
            //   if (ram_se) r <= se ? sdi : rdata[off+:len];
            // assign sdo = r;
            SigSpec rdata_slice = {Const(0, ram_width - len), rdata.extract(off, len)};
            module->addDffe(NEW_ID, host_clk, ram_se,
                module->Mux(NEW_ID, rdata_slice, sdi, se), sdo);
            module->connect(wdata.extract(off, len), sdo.extract(0, len));
        }
        module->connect(ram_di, sdi);

        mem.packed = true;
        mem.emit();

        mem_builder.append_ram(ram_di, ram_do, ram_li, ram_lo);

        // record source info for reconstruction
        extractor.add_mem(mem, slices);
    }
}

void ScanchainWorker::restore_mem_rdport_ffs(Module *module, FfChainBuilder &ff_builder)
{
    struct WorkInfo {
        Mem &mem;
        int rd_index;
        bool is_addr;
    };

    std::vector<WorkInfo> worklist;
    auto mem_list = Mem::get_all_memories(module);

    for (auto &mem : mem_list) {
        if (designinfo.check_hier_attr(Attr::NoScanchain, mem.cell))
            continue;

        for (int idx = 0; idx < GetSize(mem.rd_ports); idx++) {
            auto &rd = mem.rd_ports[idx];
            if (rd.clk_enable) {
                if (database.mem_sr_addr.count({mem.cell, idx}) > 0)
                    worklist.push_back({mem, idx, true});
                else if (database.mem_sr_data.count({mem.cell, idx}) > 0)
                    worklist.push_back({mem, idx, false});
                else
                    log_error(
                        "%s.%s: Memory has synchronous read port without source information. \n"
                        "Do not run memory_dff pass before emulator transformation.\n",
                        log_id(module), log_id(mem.cell));
            }
        }
    }

    if (worklist.empty())
        return;

    Wire *host_clk  = rewriter.wire("host_clk")->get(module);
    Wire *ff_se     = rewriter.wire("ff_se")->get(module);
    Wire *ram_se    = rewriter.wire("ram_se")->get(module);

    SigSpec sdi_list, q_list;
    SigSpec info_q, info_init;

    for (auto &work : worklist) {

        Mem &mem = work.mem;
        int rd_index = work.rd_index;

        auto &rd = mem.rd_ports[rd_index];
        int width = GetSize(rd.data);

        std::string name = mem.memid.str() + stringf("_rd_%d", rd_index);

        // reg a = 1'b0, b = 1'b1;
        // always @(posedge host_clk) a <= b;
        // always @(posedge rd.clk) if ((rd.en || rd.srst) && !ram_se) b <= ~b;
        // wire sel = a ^ b;
        // reg [..] shadow_rdata = rd.init_value;
        // assign output = sel ? rdata : shadow_rdata;
        // always @(posedge host_clk) begin
        //   if (sel || ff_se) shadow_rdata <= ff_se ? sdi : output;
        // end

        Wire *a = module->addWire(module->uniquify(name + "_a"));
        Wire *b = module->addWire(module->uniquify(name + "_b"));
        a->attributes[ID::init] = Const(0, 1);
        b->attributes[ID::init] = Const(1, 1);
        module->addDff(NEW_ID, host_clk, b, a);
        module->addDffe(NEW_ID, rd.clk,
            module->And(NEW_ID, module->Or(NEW_ID, rd.en, rd.srst), module->Not(NEW_ID, ram_se)),
            module->Not(NEW_ID, b), b);
        SigSpec sel = module->Xor(NEW_ID, a, b);

        Wire *shadow_rdata = module->addWire(module->uniquify(name + "_shadow_rdata"), width);
        shadow_rdata->attributes[ID::init] = rd.init_value;
        Wire *rdata = module->addWire(module->uniquify(name + "_rdata"), width);
        SigSpec output = rd.data;
        module->connect(output, module->Mux(NEW_ID, shadow_rdata, rdata, sel));
        rd.data = rdata;

        SigSpec sdi = module->addWire(module->uniquify(name + "_sdi"), width);
        sdi_list.append(sdi);
        q_list.append(shadow_rdata);
        module->addDffe(NEW_ID, host_clk,
            module->Or(NEW_ID, sel, ff_se),
            module->Mux(NEW_ID, output, sdi, ff_se),
            shadow_rdata);

        mem.emit();

        // if the original reg is raddr, we don't care rdata's name but only save its data
        info_q.append(work.is_addr ? shadow_rdata : rd.data);
        info_init.append(rd.init_value);

    }

    ff_builder.append_ff(sdi_list, q_list, info_q, info_init.as_const());
}

void ScanchainWorker::run()
{
    HierconnBuilder hierconn(designinfo);

    Module *wrapper = rewriter.wrapper();

    database.ff_width = ff_width;
    database.ram_width = ram_width;

    // Process modules using DFS

    FfChainBuilder ff_builder(rewriter, database, ff_width);
    MemChainBuilder mem_builder(rewriter, ram_width);

    pool<Module *> visited;
    std::vector<Module *> stack;

    stack.push_back(rewriter.target());

    while (!stack.empty()) {
        Module *module = stack.back();

        if (visited.count(module) == 0) {
            log("Processing module %s\n", log_id(module));
            instrument_ffs(module, ff_builder);
            restore_mem_rdport_ffs(module, ff_builder);
            instrument_mems(module, mem_builder);
            visited.insert(module);
        }

        bool found = false;

        for (Module *child : designinfo.children_of(module)) {
            if (visited.count(child) == 0) {
                stack.push_back(child);
                found = true;
                break;
            }
        }

        if (!found)
            stack.pop_back();
    }

    ff_builder.build();

    // Tie off scan chain connections

    auto host_clk = rewriter.wire("host_clk");
    auto mdl_clk_ff = rewriter.clock("mdl_clk_ff");
    auto mdl_clk_ram = rewriter.clock("mdl_clk_ram");

    Wire *ff_se     = rewriter.wire("ff_se")->get(wrapper);
    Wire *ff_di     = rewriter.wire("ff_di")->get(wrapper);
    Wire *ff_do     = rewriter.wire("ff_do")->get(wrapper);
    Wire *ram_sr    = rewriter.wire("ram_sr")->get(wrapper);
    Wire *ram_se    = rewriter.wire("ram_se")->get(wrapper);
    Wire *ram_sd    = rewriter.wire("ram_sd")->get(wrapper);
    Wire *ram_di    = rewriter.wire("ram_di")->get(wrapper);
    Wire *ram_do    = rewriter.wire("ram_do")->get(wrapper);

    hierconn.connect(ff_builder.ff_di, ff_di);
    hierconn.connect(ff_do, ff_builder.ff_do);
    hierconn.connect(mem_builder.ram_di, ram_di);
    hierconn.connect(ram_do, mem_builder.ram_do);

    int mem_chain_depth = 0;
    for (auto &m : database.scanchain_ram)
        mem_chain_depth += m.slices;

    Cell *li_gen = wrapper->addCell(wrapper->uniquify("\\u_li_gen"), "\\RamLastInGen");
    li_gen->setParam("\\DEPTH", Const(mem_chain_depth));
    li_gen->setPort("\\clk", host_clk->get(wrapper));
    li_gen->setPort("\\ram_sr", ram_sr);
    li_gen->setPort("\\ram_se", ram_se);
    li_gen->setPort("\\ram_sd", ram_sd);
    li_gen->setPort("\\ram_li", mem_builder.ram_li);

    // Update clock enable signals

    SigBit mdl_clk_ff_en = mdl_clk_ff->getEnable();
    mdl_clk_ff_en = wrapper->Or(NEW_ID, mdl_clk_ff_en, ff_se);
    mdl_clk_ff->setEnable(mdl_clk_ff_en);

    SigBit mdl_clk_ram_en = mdl_clk_ram->getEnable();
    mdl_clk_ram_en = wrapper->Or(NEW_ID, mdl_clk_ram_en, ram_se);
    mdl_clk_ram->setEnable(mdl_clk_ram_en);

    for (auto &info : database.user_clocks) {
        auto ff_clk = rewriter.clock(info.ff_clk);
        SigBit ff_clk_en = ff_clk->getEnable();
        ff_clk_en = wrapper->Or(NEW_ID, ff_clk_en, ff_se);
        ff_clk->setEnable(ff_clk_en);

        auto ram_clk = rewriter.clock(info.ram_clk);
        SigBit ram_clk_en = ram_clk->getEnable();
        ram_clk_en = wrapper->Or(NEW_ID, ram_clk_en, ram_se);
        ram_clk->setEnable(ram_clk_en);
    }
}

void ScanchainWorker::report_ff() {
    pool<Module *> visited;
    std::vector<Module *> stack;
    int total_width = 0;

    stack.push_back(rewriter.target());

    while (!stack.empty()) {
        Module *module = stack.back();

        if (visited.count(module) == 0) {
            for (auto cell : module->cells().to_vector()) {
                if (RTLIL::builtin_ff_cell_types().count(cell->type) == 0)
                    continue;
                total_width += GetSize(cell->getPort(ID::Q));
            }
            visited.insert(module);
        }

        bool found = false;

        for (Module *child : designinfo.children_of(module)) {
            if (visited.count(child) == 0) {
                stack.push_back(child);
                found = true;
                break;
            }
        }

        if (!found)
            stack.pop_back();
    }
    log("  total_width = %d\n", total_width);
}

void ScanchainWorker::report_mem() {
    pool<Module *> visited;
    std::vector<Module *> stack;

    stack.push_back(rewriter.target());

    while (!stack.empty()) {
        Module *module = stack.back();

        if (visited.count(module) == 0) {
            for (auto &mem : Mem::get_all_memories(module)) {
                int sync_rd = 0, async_rd = 0;
                for (auto &rd : mem.rd_ports) {
                    if (rd.clk_enable)
                        sync_rd++;
                    else
                        async_rd++;
                }
                log("  %s:\n", designinfo.flat_name_of(mem.memid, module).c_str());
                log("    width = %d\n", mem.width);
                log("    depth = %d\n", mem.size);
                log("    sync_rd = %d\n", sync_rd);
                log("    async_rd = %d\n", async_rd);
                log("    wr = %d\n", GetSize(mem.wr_ports));
            }
            visited.insert(module);
        }

        bool found = false;

        for (Module *child : designinfo.children_of(module)) {
            if (visited.count(child) == 0) {
                stack.push_back(child);
                found = true;
                break;
            }
        }

        if (!found)
            stack.pop_back();
    }
}

PRIVATE_NAMESPACE_END

void InsertScanchain::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing InsertScanchain.\n");
    ScanchainWorker worker(database, rewriter);

    log("=== Report FF before instrumentation ===\n");
    worker.report_ff();
    log("=== Report memory ===\n");
    worker.report_mem();

    worker.run();

    log("=== Report FF after instrumentation ===\n");
    worker.report_ff();
}
