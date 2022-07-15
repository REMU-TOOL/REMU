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

struct ScanchainBuilder {
    EmulationRewriter &rewriter;
    HierconnBuilder hierconn;

    Wire *ff_di, *ff_do, *ram_di, *ram_do, *ram_li, *ram_lo;

    void append_ff(Wire *ff_di, Wire *ff_do) {
        hierconn.connect(this->ff_di, ff_do);
        this->ff_di = ff_di;
    }

    void append_ram(Wire *ram_di, Wire *ram_do, Wire *ram_li, Wire *ram_lo) {
        hierconn.connect(this->ram_di, ram_do);
        this->ram_di = ram_di;
        hierconn.connect(ram_li, this->ram_lo);
        this->ram_lo = ram_lo;
    }

    ScanchainBuilder(EmulationRewriter &rewriter, int ff_width, int ram_width)
        : rewriter(rewriter), hierconn(rewriter.design())
    {
        Module *wrapper = rewriter.wrapper();
        ff_di  = ff_do  = wrapper->addWire(wrapper->uniquify("\\ff_di_do"), ff_width);
        ram_di = ram_do = wrapper->addWire(wrapper->uniquify("\\ram_di_do"), ram_width);
        ram_li = ram_lo = wrapper->addWire(wrapper->uniquify("\\ram_li_lo"));
    }
};

struct ScanchainWorker {

    EmulationRewriter &rewriter;
    DesignInfo &designinfo;
    EmulationDatabase &database;
    FfMemInfoExtractor extractor;

    int ff_width, ram_width;

    void instrument_ffs(Module *module, ScanchainBuilder &builder);
    void instrument_mems(Module *module, ScanchainBuilder &builder);
    void add_shadow_rdata(Module *module, ScanchainBuilder &builder, Mem &mem, int rd_index);
    void restore_mem_rdport_ffs(Module *module, ScanchainBuilder &builder);
    void instrument_module(Module *module, ScanchainBuilder &builder);

public:

    ScanchainWorker(EmulationDatabase &database, EmulationRewriter &rewriter) :
        rewriter(rewriter), designinfo(rewriter.design()),
        database(database),
        extractor(designinfo, rewriter.target())
    {
        ff_width = rewriter.wire("ff_di")->width();
        ram_width = rewriter.wire("ram_di")->width();
    }

    void run();

};

void ScanchainWorker::instrument_ffs(Module *module, ScanchainBuilder &builder)
{
    Wire *scan_mode = rewriter.wire("scan_mode")->get(module);
    Wire *ff_se     = rewriter.wire("ff_se")->get(module);

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

    SigSig sdi_q_list;

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
                        designinfo.hier_name_of(chunk).c_str());

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
                        designinfo.hier_name_of(chunk).c_str());
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
        sdi_q_list.first.append(sdi);
        sdi_q_list.second.append(ff.sig_q);
        ff.emit();
    }

    // pad to align data width
    int r = GetSize(sdi_q_list.first) % ff_width;
    if (r) {
        int pad = ff_width - r;
        Wire *d = module->addWire(module->uniquify("\\pad_d"), pad);
        Wire *q = module->addWire(module->uniquify("\\pad_q"), pad);
        module->addDffe(NEW_ID, rewriter.wire("host_clk")->get(module), ff_se, d, q);
        sdi_q_list.first.append(d);
        sdi_q_list.second.append(q);
    }

    // build scan chain
    int size = GetSize(sdi_q_list.first);
    for (int i = 0; i < size; i += ff_width) {
        SigSpec sdi = sdi_q_list.first.extract(i, ff_width);
        SigSpec q = sdi_q_list.second.extract(i, ff_width);
        Wire *ff_di = module->addWire(module->uniquify("\\ff_di"), ff_width);
        Wire *ff_do = module->addWire(module->uniquify("\\ff_do"), ff_width);
        module->connect(sdi, ff_di);
        module->connect(ff_do, q);
        builder.append_ff(ff_di, ff_do);
        database.scanchain_ff.push_back(extractor.ff(q, initvals(q)));
    }
}

void ScanchainWorker::instrument_mems(Module *module, ScanchainBuilder &builder)
{
    auto path = designinfo.scope_of(module);

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
                designinfo.hier_name_of(mem.cell).c_str());
            continue;
        }

        if (designinfo.check_hier_attr(Attr::NoScanchain, mem.cell)) {
            log("Ignoring mem cell %s\n",
                designinfo.hier_name_of(mem.cell).c_str());
            continue;
        }

        Wire *ram_di = module->addWire(module->uniquify("\\ram_di"), ram_width);
        Wire *ram_do = module->addWire(module->uniquify("\\ram_do"), ram_width);
        Wire *ram_li = module->addWire(module->uniquify("\\ram_li"));
        Wire *ram_lo = module->addWire(module->uniquify("\\ram_lo"));

        log("Rewriting mem cell %s\n",
            designinfo.hier_name_of(mem.cell).c_str());

        const int init_addr = mem.start_offset;
        const int last_addr = mem.start_offset + mem.size - 1;
        const int abits = ceil_log2(last_addr);
        const int slices = (mem.width + ram_width - 1) / ram_width;

        SigSpec inc = module->addWire(module->uniquify(name + "_inc"));

        // address generator
        // reg [..] addr;
        // wire [..] addr_next = addr + 1;
        // always @(posedge host_clk)
        //   if (ram_sr) addr <= init_addr;
        //   else if (ram_se && inc) addr <= addr_next;
        SigSpec addr = module->addWire(module->uniquify(name + "_addr"), abits);
        SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
        module->addSdffe(NEW_ID, host_clk, module->And(NEW_ID, ram_se, inc), ram_sr,
            addr_next, addr, Const(init_addr, abits));

        // assign addr_is_last = addr == last_addr;
        SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(last_addr, abits));

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

        for (auto &wr : mem.wr_ports) {
            // add pause signal to ports
            wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), scan_mode);
            // fix up addr width
            wr.addr.extend_u0(abits);
        }

        // add accessor to write port 0
        auto &wr = mem.wr_ports[0];
        wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), scan_mode);
        if (abits > 0)
            wr.addr = module->Mux(NEW_ID, wr.addr, addr, scan_mode);
        wr.data = module->Mux(NEW_ID, wr.data, wdata, scan_mode);

        for (auto &rd : mem.rd_ports) {
            // mask reset in scan mode
            if (rd.clk_enable)
                rd.srst = module->And(NEW_ID, rd.srst, module->Not(NEW_ID, scan_mode));
            // fix up addr width
            rd.addr.extend_u0(abits);
        }

        // add accessor to read port 0
        auto &rd = mem.rd_ports[0];
        if (abits > 0) {
            // do not use pause signal to select address input here
            // because we need to restore raddr before pause is deasserted to preserve output data
            rd.addr = module->Mux(NEW_ID, rd.addr, module->Mux(NEW_ID, addr, addr_next, inc), scan_mode);
        }
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

        builder.append_ram(ram_di, ram_do, ram_li, ram_lo);

        // record source info for reconstruction
        database.scanchain_ram.push_back(extractor.mem(mem, slices));
    }
}

void ScanchainWorker::add_shadow_rdata(Module *module, ScanchainBuilder &builder, Mem &mem, int rd_index)
{
    Wire *host_clk  = rewriter.wire("host_clk")->get(module);
    Wire *ff_se     = rewriter.wire("ff_se")->get(module);
    Wire *ram_se    = rewriter.wire("ram_se")->get(module);

    auto &rd = mem.rd_ports[rd_index];
    SigSpec orig_rdata = rd.data;

    int total_width = GetSize(rd.data);

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

    Wire *shadow_rdata = module->addWire(module->uniquify(name + "_shadow_rdata"), total_width);
    shadow_rdata->attributes[ID::init] = rd.init_value;
    Wire *rdata = module->addWire(module->uniquify(name + "_rdata"), total_width);
    SigSpec output = rd.data;
    module->connect(output, module->Mux(NEW_ID, shadow_rdata, rdata, sel));
    rd.data = rdata;

    SigSig sdi_q_list;
    sdi_q_list.first = module->addWire(module->uniquify(name + "_sdi"), total_width);
    sdi_q_list.second = shadow_rdata;
    module->addDffe(NEW_ID, host_clk,
        module->Or(NEW_ID, sel, ff_se),
        module->Mux(NEW_ID, output, sdi_q_list.first, ff_se),
        shadow_rdata);

    // pad to align data width
    int r = GetSize(sdi_q_list.first) % ff_width;
    if (r) {
        int pad = ff_width - r;
        Wire *d = module->addWire(module->uniquify(name + "_pad_d"), pad);
        Wire *q = module->addWire(module->uniquify(name + "_pad_q"), pad);
        module->addDffe(NEW_ID, host_clk, ff_se, d, q);
        sdi_q_list.first.append(d);
        sdi_q_list.second.append(q);
    }

    // build scan chain
    for (int i = 0; i < total_width; i += ff_width) {
        int w = total_width - i;
        if (w > ff_width) w = ff_width;
        SigSpec sdi = sdi_q_list.first.extract(i, ff_width);
        SigSpec q = sdi_q_list.second.extract(i, ff_width);
        Wire *ff_di = module->addWire(module->uniquify("\\ff_di"), ff_width);
        Wire *ff_do = module->addWire(module->uniquify("\\ff_do"), ff_width);
        module->connect(sdi, ff_di);
        module->connect(ff_do, q);
        builder.append_ff(ff_di, ff_do);
        database.scanchain_ff.push_back(extractor.ff(
            orig_rdata.extract(i, w), rd.init_value.extract(i, w)));
    }

    mem.emit();
}

void ScanchainWorker::restore_mem_rdport_ffs(Module *module, ScanchainBuilder &builder)
{
    auto path = designinfo.scope_of(module);

    for (auto &mem : Mem::get_all_memories(module)) {
        if (designinfo.check_hier_attr(Attr::NoScanchain, mem.cell))
            continue;

        for (int idx = 0; idx < GetSize(mem.rd_ports); idx++) {
            auto &rd = mem.rd_ports[idx];
            if (rd.clk_enable) {
                if (database.mem_sr_addr.count({mem.cell, idx}) > 0)
                    add_shadow_rdata(module, builder, mem, idx);
                else if (database.mem_sr_data.count({mem.cell, idx}) > 0)
                    add_shadow_rdata(module, builder, mem, idx);
                else
                    log_error(
                        "%s.%s: Memory has synchronous read port without source information. \n"
                        "Do not run memory_dff pass before emulator transformation.\n",
                        log_id(module), log_id(mem.cell));
            }
        }
    }
}

void ScanchainWorker::instrument_module(Module *module, ScanchainBuilder &builder)
{
    // process FFs
    instrument_ffs(module, builder);
    // restore merged ffs in read ports
    restore_mem_rdport_ffs(module, builder);
    // process mems
    instrument_mems(module, builder);
}

void ScanchainWorker::run()
{
    HierconnBuilder hierconn(designinfo);

    Module *wrapper = rewriter.wrapper();

    database.ff_width = ff_width;
    database.ram_width = ram_width;

    // Process modules using DFS

    ScanchainBuilder builder(rewriter, ff_width, ram_width);

    pool<Module *> visited;
    std::vector<Module *> stack;

    stack.push_back(rewriter.target());

    while (!stack.empty()) {
        Module *module = stack.back();

        if (visited.count(module) == 0) {
            log("Processing module %s\n", log_id(module));
            instrument_module(module, builder);
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

    hierconn.connect(builder.ff_di, ff_di);
    hierconn.connect(ff_do, builder.ff_do);
    hierconn.connect(builder.ram_di, ram_di);
    hierconn.connect(ram_do, builder.ram_do);

    int mem_chain_depth = 0;
    for (auto &m : database.scanchain_ram)
        mem_chain_depth += m.slices;

    Cell *li_gen = wrapper->addCell(wrapper->uniquify("\\u_li_gen"), "\\RamLastInGen");
    li_gen->setParam("\\DEPTH", Const(mem_chain_depth));
    li_gen->setPort("\\clk", host_clk->get(wrapper));
    li_gen->setPort("\\ram_sr", ram_sr);
    li_gen->setPort("\\ram_se", ram_se);
    li_gen->setPort("\\ram_sd", ram_sd);
    li_gen->setPort("\\ram_li", builder.ram_li);

    // Update clock enable signals

    SigBit mdl_clk_ff_en = mdl_clk_ff->getEnable();
    mdl_clk_ff_en = wrapper->Or(NEW_ID, mdl_clk_ff_en, ff_se);
    mdl_clk_ff->setEnable(mdl_clk_ff_en);

    SigBit mdl_clk_ram_en = mdl_clk_ram->getEnable();
    mdl_clk_ram_en = wrapper->Or(NEW_ID, mdl_clk_ram_en, ram_se);
    mdl_clk_ram->setEnable(mdl_clk_ram_en);

    for (auto &it : database.dutclocks) {
        auto ff_clk = rewriter.clock(it.second.ff_clk);
        SigBit ff_clk_en = ff_clk->getEnable();
        ff_clk_en = wrapper->Or(NEW_ID, ff_clk_en, ff_se);
        ff_clk->setEnable(ff_clk_en);

        auto ram_clk = rewriter.clock(it.second.ram_clk);
        SigBit ram_clk_en = ram_clk->getEnable();
        ram_clk_en = wrapper->Or(NEW_ID, ram_clk_en, ram_se);
        ram_clk->setEnable(ram_clk_en);
    }
}

PRIVATE_NAMESPACE_END

void InsertScanchain::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing InsertScanchain.\n");
    ScanchainWorker worker(database, rewriter);
    worker.run();
}
