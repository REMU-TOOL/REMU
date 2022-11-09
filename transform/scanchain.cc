#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "attr.h"
#include "port.h"
#include "scanchain.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

void ScanchainWorker::instrument_module_ff(Module *module, SigSpec ff_di, SigSpec ff_do, std::vector<FFInfo> &info_list)
{
    Wire *scan_mode = CommonPort::get(module, CommonPort::NAME_SCAN_MODE);

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

    SigMap sigmap;
    FfInitVals initvals;
    sigmap.set(module);
    initvals.set(&sigmap, module);

    SigSpec sdi_list, q_list;

    for (auto cell : module->cells().to_vector()) {
        if (RTLIL::builtin_ff_cell_types().count(cell->type) == 0)
            continue;

        FfData ff(&initvals, cell);
        pool<int> removed_bits;

        int offset = 0;
        for (auto chunk : ff.sig_q.chunks()) {
            if (chunk.is_wire()) {
                if (chunk.wire->get_bool_attribute(Attr::NoScanchain)) {
                    log("Ignoring FF %s\n",
                        pretty_name(chunk).c_str());

                    std::vector<int> bits;
                    for (int i = offset; i < offset + chunk.size(); i++) {
                        bits.push_back(i);
                        removed_bits.insert(i);
                    }
                    FfData ignored_ff = ff.slice(bits);
                    ignored_ff.emit();
                }
                else {
                    log("Rewriting FF %s\n",
                        pretty_name(chunk).c_str());
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
        SigSpec sdi = module->addWire(NEW_ID, GetSize(ff.sig_d));
        ff.sig_d = module->Mux(NEW_ID, ff.sig_d, sdi, scan_mode);
        sdi_list.append(sdi);
        q_list.append(ff.sig_q);
        ff.emit();
    }

    module->connect({sdi_list, ff_do}, {ff_di, q_list});

    for (auto &chunk : q_list.chunks()) {
        log_assert(chunk.is_wire());
        FFInfo info;
        info.name = {chunk.wire->name};
        info.width = chunk.width;
        info.offset = chunk.offset;
        info.init_data = initvals(SigSpec(chunk));
        info_list.push_back(std::move(info));
    }
}

void ScanchainWorker::restore_sync_read_port_ff(Module *module, SigSpec ff_di, SigSpec ff_do, std::vector<FFInfo> &info_list)
{
    Wire *host_clk  = CommonPort::get(module, CommonPort::NAME_HOST_CLK);
    Wire *ff_se     = CommonPort::get(module, CommonPort::NAME_FF_SE);
    Wire *ram_se    = CommonPort::get(module, CommonPort::NAME_RAM_SE);

    struct WorkInfo {
        Mem &mem;
        int rd_index;
        bool is_addr;
    };

    std::vector<WorkInfo> worklist;
    auto mem_list = Mem::get_all_memories(module);

    for (auto &mem : mem_list) {
        if (mem.get_bool_attribute(Attr::NoScanchain))
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

    module->connect({sdi_list, ff_do}, {ff_di, q_list});

    for (auto &chunk : info_q.chunks()) {
        log_assert(chunk.is_wire());
        FFInfo info;
        info.name = {chunk.wire->name};
        info.width = chunk.width;
        info.offset = chunk.offset;
        info.init_data = info_init.as_const();
        info_list.push_back(std::move(info));
    }
}

void ScanchainWorker::instrument_module_ram(Module *module, SigSpec ram_di, SigSpec ram_do, SigSpec ram_li, SigSpec ram_lo, std::vector<RAMInfo> &info_list)
{
    Wire *host_clk  = CommonPort::get(module, CommonPort::NAME_HOST_CLK);
    Wire *scan_mode = CommonPort::get(module, CommonPort::NAME_SCAN_MODE);
    Wire *ram_sr    = CommonPort::get(module, CommonPort::NAME_RAM_SR);
    Wire *ram_se    = CommonPort::get(module, CommonPort::NAME_RAM_SE);
    Wire *ram_sd    = CommonPort::get(module, CommonPort::NAME_RAM_SD);

    SigSpec ram_di_list, ram_do_list, ram_li_list, ram_lo_list;

    for (auto &mem : Mem::get_all_memories(module)) {
        std::string name = mem.memid.str();

        // exclude mem cells without write ports (ROM)
        if (mem.wr_ports.size() == 0) {
            log("Ignoring ROM %s\n",
                pretty_name(mem.cell).c_str());
            continue;
        }

        if (mem.get_bool_attribute(Attr::NoScanchain)) {
            log("Ignoring RAM %s\n",
                pretty_name(mem.cell).c_str());
            continue;
        }

        log("Rewriting RAM %s\n",
            pretty_name(mem.memid).c_str());

        const int abits = ceil_log2(mem.size);
        const int cbits = ceil_log2(mem.width);

        SigSpec run_flag = module->addWire(module->uniquify(name + "_run_flag"));
        SigSpec addr_inc = module->addWire(module->uniquify(name + "_addr_inc"));

        // address generator
        // reg [abits-1:0] addr;
        // wire [abits-1:0] addr_next = addr + 1;
        // always @(posedge host_clk)
        //   if (ram_sr) addr <= 0;
        //   else if (ram_se && addr_inc) addr <= addr_next;
        SigSpec addr = module->addWire(module->uniquify(name + "_addr"), abits);
        SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
        module->addSdffe(NEW_ID, host_clk, module->And(NEW_ID, ram_se, addr_inc), ram_sr,
            addr_next, addr, Const(0, abits));

        // assign addr_is_last = addr == mem.size - 1;
        SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(mem.size - 1, abits));

        SigSpec cnt_is_last;
        if (mem.width > 1) {
            // word bit counter
            // if (mem.width > 1) begin
            //   reg [cbits-1:0] cnt;
            //   assign cnt_is_last = cnt == 0;
            //   always @(posedge host_clk)
            //     if (addr_inc) cnt <= mem.width - 1;
            //     else if (ram_se) cnt <= cnt - !cnt_is_last;
            // end
            SigSpec cnt = module->addWire(module->uniquify(name + "_cnt"), cbits);
            cnt_is_last = module->Eq(NEW_ID, cnt, Const(0, cbits));
            module->addSdffe(NEW_ID, host_clk, ram_se, addr_inc,
                module->Sub(NEW_ID, cnt, {Const(0, cbits - 1), module->Not(NEW_ID, cnt_is_last)}),
                cnt, Const(mem.width - 1, cbits));
        }
        else {
            // else
            //   assign cnt_is_last == 1;
            cnt_is_last = State::S1;
        }

        SigSpec last_i = module->addWire(NEW_ID);
        SigSpec last_o = module->addWire(NEW_ID);

        // if (mem.size > 1)
        //   assign last_o = cnt_is_last && addr_is_last
        // else
        //   assign last_o = last_i
        if (mem.size > 1)
            module->connect(last_o, module->And(NEW_ID, cnt_is_last, addr_is_last));
        else
            module->connect(last_o, last_i);

        // always @(posedge host_clk)
        //   if (ram_sr || last_o) run_flag <= 0;
        //   else if (last_i) run_flag <= 1;
        module->addSdffe(NEW_ID, host_clk,
            last_i, module->Or(NEW_ID, ram_sr, last_o), State::S1, run_flag, State::S0);

        // assign addr_inc = cnt_is_last && run_flag || last_i;
        module->connect(addr_inc,
            module->Or(NEW_ID,
                module->And(NEW_ID, cnt_is_last, run_flag),
                last_i));

        SigSpec se = module->addWire(module->uniquify(name + "_se"));
        SigSpec we = module->addWire(module->uniquify(name + "_we"));
        SigSpec rdata = module->addWire(module->uniquify(name + "_rdata"), mem.width);
        SigSpec wdata = module->addWire(module->uniquify(name + "_wdata"), mem.width);

        // assign se = ram_sd || !addr_inc;
        // assign we = ram_sd && addr_inc;
        module->connect(se, module->Or(NEW_ID, ram_sd, module->Not(NEW_ID, addr_inc)));
        module->connect(we, module->And(NEW_ID, ram_sd, addr_inc));

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
        SigSpec scan_raddr;
        if (rd.clk_enable) {
            rd.en = module->Or(NEW_ID, rd.en, scan_mode);
            // bypass next addr for sync read port
            scan_raddr = module->Mux(NEW_ID, addr, addr_next, addr_inc);
        }
        else {
            scan_raddr = addr;
        }
        scan_raddr.extend_u0(extended_addr_len);
        scan_raddr = module->Add(NEW_ID, scan_raddr, Const(mem.start_offset, extended_addr_len));
        rd.addr = module->Mux(NEW_ID, rd.addr, scan_raddr, scan_mode);
        module->connect(rdata, rd.data);

        // create scan chain registers
        SigSpec sdi = module->addWire(module->uniquify(name + "_sdi"), mem.width);
        SigSpec sdo = module->addWire(module->uniquify(name + "_sdo"), mem.width);
        // always @(posedge host_clk)
        //   if (ram_se) sdo <= se ? sdi : rdata;
        // assign wdata = sdo;
        module->addDffe(NEW_ID, host_clk, ram_se,
            module->Mux(NEW_ID, rdata, sdi, se), sdo);
        module->connect(wdata, sdo);

        ram_di_list.append(sdi);
        ram_do_list.append(sdo);
        ram_li_list.append(last_i);
        ram_lo_list.append(last_o);

        mem.packed = true;
        mem.emit();

        RAMInfo info;
        info.name = {mem.memid};
        info.init_data = mem.get_init_data();
        info_list.push_back(std::move(info));
    }

    module->connect({ram_di_list, ram_do}, {ram_di, ram_do_list});
    module->connect({ram_lo, ram_li_list}, {ram_lo_list, ram_li});
}

template<typename T>
inline void copy_info_from_child(std::vector<T> &to, const std::vector<T> &from, IdString scope)
{
    for (auto info : from) {
        info.name.insert(info.name.begin(), scope);
        to.push_back(std::move(info));
    }
}

void ScanchainWorker::instrument_module(Module *module)
{
    Wire *ff_se     = CommonPort::get(module, CommonPort::NAME_FF_SE);
    Wire *ff_di     = CommonPort::get(module, CommonPort::NAME_FF_DI);
    Wire *ff_do     = CommonPort::get(module, CommonPort::NAME_FF_DO);
    Wire *ram_sr    = CommonPort::get(module, CommonPort::NAME_RAM_SR);
    Wire *ram_se    = CommonPort::get(module, CommonPort::NAME_RAM_SE);
    Wire *ram_sd    = CommonPort::get(module, CommonPort::NAME_RAM_SD);
    Wire *ram_di    = CommonPort::get(module, CommonPort::NAME_RAM_DI);
    Wire *ram_do    = CommonPort::get(module, CommonPort::NAME_RAM_DO);
    Wire *ram_li    = CommonPort::get(module, CommonPort::NAME_RAM_LI);
    Wire *ram_lo    = CommonPort::get(module, CommonPort::NAME_RAM_LO);

    std::vector<FFInfo> ff_list;
    std::vector<RAMInfo> ram_list;

    SigSpec sig_ff_di;
    SigSpec sig_ff_do = ff_di;
    SigSpec sig_ram_di;
    SigSpec sig_ram_do = ram_di;
    SigSpec sig_ram_li;
    SigSpec sig_ram_lo = ram_li;

    // Process FFs & RAMs in this module

    sig_ff_di = sig_ff_do;
    sig_ff_do = module->addWire(NEW_ID);
    instrument_module_ff(module, sig_ff_di, sig_ff_do, ff_list);

    sig_ff_di = sig_ff_do;
    sig_ff_do = module->addWire(NEW_ID);
    restore_sync_read_port_ff(module, sig_ff_di, sig_ff_do, ff_list);

    sig_ram_di = sig_ram_do;
    sig_ram_do = module->addWire(NEW_ID);
    sig_ram_li = sig_ram_lo;
    sig_ram_lo = module->addWire(NEW_ID);
    instrument_module_ram(module, sig_ram_di, sig_ram_do, sig_ram_li, sig_ram_lo, ram_list);

    // Append FFs & RAMs in submodules

    for (Cell *cell : module->cells()) {
        if (!hier.celltypes.cell_known(cell->type))
            continue;

        if (cell->get_bool_attribute(Attr::NoScanchain)) {
            log("Ignoring cell %s\n", log_id(cell));
            continue;
        }

        sig_ff_di = sig_ff_do;
        sig_ff_do = module->addWire(NEW_ID);
        sig_ram_di = sig_ram_do;
        sig_ram_do = module->addWire(NEW_ID);
        sig_ram_li = sig_ram_lo;
        sig_ram_lo = module->addWire(NEW_ID);

        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_FF_SE).id_str,    ff_se);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_FF_DI).id_str,    sig_ff_di);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_FF_DO).id_str,    sig_ff_do);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_SR).id_str,   ram_sr);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_SE).id_str,   ram_se);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_SD).id_str,   ram_sd);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_DI).id_str,   sig_ram_di);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_DO).id_str,   sig_ram_do);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_LI).id_str,   sig_ram_li);
        cell->setPort(CommonPort::info_by_id(CommonPort::NAME_RAM_LO).id_str,   sig_ram_lo);

        copy_info_from_child(ff_list, ff_lists.at(cell->type), cell->name);
        copy_info_from_child(ram_list, ram_lists.at(cell->type), cell->name);

        cell->type = derived_name(cell->type);
    }

    module->connect(ff_do, sig_ff_do);
    module->connect(ram_do, sig_ram_do);
    module->connect(ram_lo, sig_ram_lo);

    // Note: module->name here is its original name
    ff_lists[module->name] = ff_list;
    ram_lists[module->name] = ram_list;
}

void ScanchainWorker::run()
{
    // Note: in instrumentation process new modules are created,
    //       but hier contains the original design hierarchy

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = node.data.module;
        IdString newid = derived_name(module->name);

        log("Creating instrumented module %s from %s\n", log_id(newid), log_id(module));

        Module *newmod = module->clone();
        instrument_module(newmod);

        // Rename new module AFTER instrumentation
        newmod->name = newid;
        hier.design->add(newmod);
    }

    database.ff_list = ff_lists.at(hier.top);
    database.ram_list = ram_lists.at(hier.top);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestScanchain : public Pass {
    EmuTestScanchain() : Pass("emu_test_scanchain", "test scanchain functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_SCANCHAIN pass.\n");

        EmulationDatabase database(design);
        PortTransformer port(design, database);
        port.promote();
        ScanchainWorker worker(design, database);
        worker.run();
        database.write_yaml("output.yml");
    }
} EmuTestScanchain;

PRIVATE_NAMESPACE_END
