#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "attr.h"
#include "port.h"
#include "hier.h"
#include "database.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace REMU;

PRIVATE_NAMESPACE_BEGIN

struct ScanchainWorker
{
    Hierarchy hier;
    EmulationDatabase &database;

    Yosys::dict<Yosys::IdString, Yosys::dict<std::vector<std::string>, SysInfo::WireInfo>> all_wire_infos; // module name -> {wire name -> info}
    Yosys::dict<Yosys::IdString, Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo>> all_ram_infos; // module name -> {ram name -> info}

    Yosys::dict<Yosys::IdString, std::vector<SysInfo::ScanFFInfo>> ff_lists;
    Yosys::dict<Yosys::IdString, std::vector<SysInfo::ScanRAMInfo>> ram_lists;

    static Yosys::IdString derived_name(Yosys::IdString orig_name)
    {
        return orig_name.str() + "_SCANINST";
    }

    void handle_ignored_ff(Yosys::Module *module, Yosys::FfInitVals &initvals);

    void instrument_module_ff
    (
        Yosys::Module *module,
        Yosys::SigSpec ff_di,
        Yosys::SigSpec ff_do,
        Yosys::SigSpec &ff_sigs,
        std::vector<SysInfo::ScanFFInfo> &info_list
    );

    void restore_sync_read_port_ff
    (
        Yosys::Module *module,
        Yosys::SigSpec ff_di,
        Yosys::SigSpec ff_do,
        Yosys::SigSpec &ff_sigs,
        std::vector<SysInfo::ScanFFInfo> &info_list
    );

    void instrument_module_ram
    (
        Yosys::Module *module,
        Yosys::SigSpec ram_di,
        Yosys::SigSpec ram_do,
        Yosys::SigSpec ram_li,
        Yosys::SigSpec ram_lo,
        Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos,
        std::vector<SysInfo::ScanRAMInfo> &info_list
    );

    void parse_dissolved_rams
    (
        Yosys::Module *module,
        Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos
    );

    void instrument_module(Yosys::Module *module);
    void tieoff_ram_last(Yosys::Module *module);
    void run();

    ScanchainWorker(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

void ScanchainWorker::handle_ignored_ff(Module *module, FfInitVals &initvals)
{
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
                    ignored_ff.attributes[Attr::NoScanchain] = Const(1);
                    ignored_ff.emit();
                }
                else {
                    log("Selecting FF %s\n",
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
        ff.emit();
    }
}

void ScanchainWorker::instrument_module_ff
(
    Module *module,
    SigSpec ff_di,
    SigSpec ff_do,
    SigSpec &ff_sigs,
    std::vector<SysInfo::ScanFFInfo> &info_list
)
{
    Wire *scan_mode = CommonPort::get(module, CommonPort::PORT_SCAN_MODE);

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

    for (auto cell : module->cells().to_vector()) {
        if (RTLIL::builtin_ff_cell_types().count(cell->type) == 0)
            continue;

        if (cell->get_bool_attribute(Attr::NoScanchain))
            continue;

        FfData ff(nullptr, cell);
        pool<int> removed_bits;

        log("Rewriting FF %s\n",
            pretty_name(ff.sig_q).c_str());

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
        if (chunk.wire->get_bool_attribute(Attr::AnonymousFF)) {
            info_list.push_back({
                .name = {},
                .width = chunk.width,
                .offset = 0,
            });
        }
        else {
            info_list.push_back({
                .name = {id2str(chunk.wire->name)},
                .width = chunk.width,
                .offset = chunk.offset,
            });
            ff_sigs.append(chunk);
        }
    }
}

void ScanchainWorker::restore_sync_read_port_ff
(
    Module *module,
    SigSpec ff_di,
    SigSpec ff_do,
    SigSpec &ff_sigs,
    std::vector<SysInfo::ScanFFInfo> &info_list
)
{
    Wire *host_clk  = CommonPort::get(module, CommonPort::PORT_HOST_CLK);
    Wire *ff_se     = CommonPort::get(module, CommonPort::PORT_FF_SE);
    Wire *ram_se    = CommonPort::get(module, CommonPort::PORT_RAM_SE);

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

        std::vector<bool> is_addr_port, is_data_port;
        is_addr_port.assign(mem.rd_ports.size(), false);
        is_data_port.assign(mem.rd_ports.size(), false);
        for (auto idx : mem.get_intvec_attribute("\\mem_addr_rd_port_list"))
            is_addr_port[idx] = true;
        for (auto idx : mem.get_intvec_attribute("\\mem_data_rd_port_list"))
            is_data_port[idx] = true;

        for (int idx = 0; idx < GetSize(mem.rd_ports); idx++) {
            auto &rd = mem.rd_ports[idx];
            if (rd.clk_enable) {
                if (is_addr_port.at(idx))
                    worklist.push_back({mem, idx, true});
                else if (is_data_port.at(idx))
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
        if (work.is_addr) {
            info_list.push_back({
                .name = {},
                .width = shadow_rdata->width,
                .offset = 0,
            });
        }
        else {
            for (auto &chunk : output.chunks()) {
                log_assert(chunk.is_wire());
                info_list.push_back({
                    .name = {id2str(chunk.wire->name)},
                    .width = chunk.width,
                    .offset = chunk.offset,
                });
            }
            ff_sigs.append(output);
        }
    }

    module->connect({sdi_list, ff_do}, {ff_di, q_list});
}

void ScanchainWorker::instrument_module_ram
(
    Module *module,
    SigSpec ram_di,
    SigSpec ram_do,
    SigSpec ram_li,
    SigSpec ram_lo,
    dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos,
    std::vector<SysInfo::ScanRAMInfo> &info_list
)
{
    Wire *host_clk  = CommonPort::get(module, CommonPort::PORT_HOST_CLK);
    Wire *scan_mode = CommonPort::get(module, CommonPort::PORT_SCAN_MODE);
    Wire *ram_sr    = CommonPort::get(module, CommonPort::PORT_RAM_SR);
    Wire *ram_se    = CommonPort::get(module, CommonPort::PORT_RAM_SE);
    Wire *ram_sd    = CommonPort::get(module, CommonPort::PORT_RAM_SD);

    SigSpec ram_di_list, ram_do_list, ram_li_list, ram_lo_list;

    for (auto &mem : Mem::get_all_memories(module)) {
        std::string name = mem.memid.str();

        // exclude mem cells without write ports (ROM)
        if (mem.wr_ports.size() == 0) {
            log("Ignoring ROM %s\n",
                log_id(mem.memid));
            continue;
        }

        if (mem.get_bool_attribute(Attr::NoScanchain)) {
            log("Ignoring RAM %s\n",
                log_id(mem.memid));
            continue;
        }

        log("Rewriting RAM %s\n",
            log_id(mem.memid));

        if (mem.start_offset < 0)
            log_error("RAM %s has a negative start offset (%d) which is not supported\n",
                log_id(mem.memid),
                mem.start_offset);

        const int abits = ceil_log2(mem.size + mem.start_offset);
        const int cbits = ceil_log2(mem.width);

        SigSpec run_flag = module->addWire(module->uniquify(name + "_run_flag"));
        SigSpec addr_inc = module->addWire(module->uniquify(name + "_addr_inc"));

        // address generator
        // reg [abits-1:0] addr;
        // wire [abits-1:0] addr_next = addr + 1;
        // always @(posedge host_clk)
        //   if (ram_sr) addr <= mem.start_offset;
        //   else if (ram_se && addr_inc) addr <= addr_next;
        SigSpec addr = module->addWire(module->uniquify(name + "_addr"), abits);
        SigSpec addr_next = module->Add(NEW_ID, addr, Const(1, abits));
        module->addSdffe(NEW_ID, host_clk, module->And(NEW_ID, ram_se, addr_inc), ram_sr,
            addr_next, addr, Const(mem.start_offset, abits));

        // assign addr_is_last = addr == mem.size + mem.start_offset - 1;
        SigSpec addr_is_last = module->Eq(NEW_ID, addr, Const(mem.size + mem.start_offset- 1, abits));

        SigSpec cnt_is_last;
        if (mem.width > 1) {
            // word bit counter
            // if (mem.width > 1) begin
            //   reg [cbits-1:0] cnt;
            //   assign cnt_is_last = cnt == 0;
            //   always @(posedge host_clk)
            //     if (ram_se) cnt <= addr_inc ? mem.width - 1 : cnt - !cnt_is_last;
            // end
            SigSpec cnt = module->addWire(module->uniquify(name + "_cnt"), cbits);
            cnt_is_last = module->Eq(NEW_ID, cnt, Const(0, cbits));
            module->addDffe(NEW_ID, host_clk, ram_se,
                module->Mux(NEW_ID,
                    module->Sub(NEW_ID, cnt, {Const(0, cbits - 1), module->Not(NEW_ID, cnt_is_last)}),
                    Const(mem.width - 1, cbits),
                    addr_inc),
                cnt);
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
        //   if (ram_sr) run_flag <= 0;
        //   else if (ram_se) run_flag <= (last_i || run_flag) && !last_o;
        module->addSdffe(NEW_ID, host_clk, ram_se, ram_sr,
            module->And(NEW_ID, module->Or(NEW_ID, last_i, run_flag), module->Not(NEW_ID, last_o)),
            run_flag, State::S0);

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

        for (auto &wr : mem.wr_ports) {
            // add pause signal to ports
            wr.en = module->Mux(NEW_ID, wr.en, Const(0, GetSize(wr.en)), scan_mode);
        }

        // add accessor to write port 0
        auto &wr = mem.wr_ports[0];
        wr.en = module->Mux(NEW_ID, wr.en, SigSpec(we, mem.width), scan_mode);
        SigSpec scan_waddr = addr;
        // FIXME: adjusting original address width may result in inconsistent behavior
        wr.addr.extend_u0(abits);
        wr.addr = module->Mux(NEW_ID, wr.addr, scan_waddr, scan_mode);
        wr.data = module->Mux(NEW_ID, wr.data, wdata, scan_mode);

        for (auto &rd : mem.rd_ports) {
            // mask reset in scan mode
            if (rd.clk_enable)
                rd.srst = module->And(NEW_ID, rd.srst, module->Not(NEW_ID, scan_mode));
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
        // FIXME: adjusting original address width may result in inconsistent behavior
        rd.addr.extend_u0(abits);
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

        Const init_data;
        bool init_zero;
        if (mem.inits.empty()) {
            init_zero = true;
        }
        else {
            init_data = mem.get_init_data();
            init_zero = init_data.is_fully_undef() || init_data.is_fully_zero();
            if (!init_zero)
                for (auto &b : init_data)
                    b = b == State::S1 ? State::S1 : State::S0;
        }

        info_list.push_back({
            .name = {id2str(mem.memid)},
            .width = mem.width,
            .depth = mem.size,
        });
        ram_infos[{id2str(mem.memid)}] = {
            .width = mem.width,
            .depth = mem.size,
            .start_offset = mem.start_offset,
            .init_zero = init_zero,
            .init_data = init_zero ? "" : init_data.as_string(),
            .dissolved = false,
        };
    }

    module->connect({ram_di_list, ram_do}, {ram_di, ram_do_list});
    module->connect({ram_lo, ram_li_list}, {ram_lo_list, ram_li});
}

void ScanchainWorker::parse_dissolved_rams
(
    Module *module,
    dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos
)
{
    auto names = module->get_strpool_attribute("\\dissolved_mems");
    for (auto &name : names) {
        auto info = module->get_intvec_attribute("\\dissolved_mem_" + name);
        if (info.size() == 3) {
            ram_infos[{name}] = {
                .width = info.at(0),
                .depth = info.at(1),
                .start_offset = info.at(2),
                .init_zero = true, // RAMs with init data are never dissolved
                .init_data = "",
                .dissolved = true,
            };
        }
    }
}

template<typename T>
inline void copy_list_from_child(std::vector<T> &to, const std::vector<T> &from, IdString scope)
{
    for (auto info : from) {
        if (!info.name.empty())
            info.name.insert(info.name.begin(), id2str(scope));
        to.push_back(std::move(info));
    }
}

template<typename T>
inline void copy_dict_from_child
(
    dict<std::vector<std::string>, T> &to,
    const dict<std::vector<std::string>, T> &from,
    IdString scope
)
{
    for (auto x : from) {
        x.first.insert(x.first.begin(), id2str(scope));
        to.insert(std::move(x));
    }
}

void ScanchainWorker::instrument_module(Module *module)
{
    Wire *ff_se     = CommonPort::get(module, CommonPort::PORT_FF_SE);
    Wire *ff_di     = CommonPort::get(module, CommonPort::PORT_FF_DI);
    Wire *ff_do     = CommonPort::get(module, CommonPort::PORT_FF_DO);
    Wire *ram_sr    = CommonPort::get(module, CommonPort::PORT_RAM_SR);
    Wire *ram_se    = CommonPort::get(module, CommonPort::PORT_RAM_SE);
    Wire *ram_sd    = CommonPort::get(module, CommonPort::PORT_RAM_SD);
    Wire *ram_di    = CommonPort::get(module, CommonPort::PORT_RAM_DI);
    Wire *ram_do    = CommonPort::get(module, CommonPort::PORT_RAM_DO);
    Wire *ram_li    = CommonPort::get(module, CommonPort::PORT_RAM_LI);
    Wire *ram_lo    = CommonPort::get(module, CommonPort::PORT_RAM_LO);

    SigSpec sig_ff_di = ff_do;
    SigSpec sig_ff_do;
    SigSpec sig_ram_di = ram_do;
    SigSpec sig_ram_do;
    SigSpec sig_ram_li;
    SigSpec sig_ram_lo = ram_li;

    // Process FFs & RAMs in this module

    SigMap sigmap;
    FfInitVals initvals;
    sigmap.set(module);
    initvals.set(&sigmap, module);

    for (auto &mem : Mem::get_all_memories(module))
        for (auto &rd : mem.rd_ports)
            initvals.set_init(rd.data, rd.init_value);

    handle_ignored_ff(module, initvals);

    SigSpec ff_sigs;

    sig_ff_do = sig_ff_di;
    sig_ff_di = module->addWire(NEW_ID);
    instrument_module_ff(module, sig_ff_di, sig_ff_do, ff_sigs, ff_lists[module->name]);

    sig_ff_do = sig_ff_di;
    sig_ff_di = module->addWire(NEW_ID);
    restore_sync_read_port_ff(module, sig_ff_di, sig_ff_do, ff_sigs, ff_lists[module->name]);

    ff_sigs.sort_and_unify();
    auto &wire_infos = all_wire_infos[module->name];
    for (auto &chunk : ff_sigs.chunks()) {
        Const init_data = initvals(SigSpec(chunk.wire));
        bool init_zero = init_data.is_fully_undef() || init_data.is_fully_zero();
        if (!init_zero)
            for (auto &b : init_data)
                b = b == State::S1 ? State::S1 : State::S0;
        wire_infos[{id2str(chunk.wire->name)}] = {
            .width = chunk.wire->width,
            .start_offset = chunk.wire->start_offset,
            .upto = chunk.wire->upto,
            .init_zero = init_zero,
            .init_data = init_zero ? "" : init_data.as_string(),
        };
    }

    sig_ram_do = sig_ram_di;
    sig_ram_di = module->addWire(NEW_ID);
    sig_ram_li = sig_ram_lo;
    sig_ram_lo = module->addWire(NEW_ID);
    instrument_module_ram(module, sig_ram_di, sig_ram_do, sig_ram_li, sig_ram_lo,
        all_ram_infos[module->name], ram_lists[module->name]);

    // Parse dissolved mem info

    parse_dissolved_rams(module, all_ram_infos[module->name]);

    // Append FFs & RAMs in submodules

    for (Cell *cell : module->cells()) {
        if (!hier.celltypes.cell_known(cell->type))
            continue;

        if (cell->get_bool_attribute(Attr::NoScanchain)) {
            log("Ignoring cell %s\n", log_id(cell));
            continue;
        }

        sig_ff_do = sig_ff_di;
        sig_ff_di = module->addWire(NEW_ID);
        sig_ram_do = sig_ram_di;
        sig_ram_di = module->addWire(NEW_ID);
        sig_ram_li = sig_ram_lo;
        sig_ram_lo = module->addWire(NEW_ID);

        cell->setPort(CommonPort::PORT_FF_SE.id,    ff_se);
        cell->setPort(CommonPort::PORT_FF_DI.id,    sig_ff_di);
        cell->setPort(CommonPort::PORT_FF_DO.id,    sig_ff_do);
        cell->setPort(CommonPort::PORT_RAM_SR.id,   ram_sr);
        cell->setPort(CommonPort::PORT_RAM_SE.id,   ram_se);
        cell->setPort(CommonPort::PORT_RAM_SD.id,   ram_sd);
        cell->setPort(CommonPort::PORT_RAM_DI.id,   sig_ram_di);
        cell->setPort(CommonPort::PORT_RAM_DO.id,   sig_ram_do);
        cell->setPort(CommonPort::PORT_RAM_LI.id,   sig_ram_li);
        cell->setPort(CommonPort::PORT_RAM_LO.id,   sig_ram_lo);

        copy_list_from_child(ff_lists[module->name], ff_lists.at(cell->type), cell->name);
        copy_list_from_child(ram_lists[module->name], ram_lists.at(cell->type), cell->name);
        copy_dict_from_child(all_wire_infos[module->name], all_wire_infos.at(cell->type), cell->name);
        copy_dict_from_child(all_ram_infos[module->name], all_ram_infos.at(cell->type), cell->name);

        cell->type = derived_name(cell->type);
    }

    module->connect(sig_ff_di, ff_di);
    module->connect(sig_ram_di, ram_di);
    module->connect(ram_lo, sig_ram_lo);
}

void ScanchainWorker::tieoff_ram_last(Module *module)
{
    auto &ram_list = ram_lists.at(module->name);
    int depth = 0; // RAM chain depth is the sum of RAM widths
    for (auto &ram : ram_list)
        depth += ram.width;

    const int cntbits = ceil_log2(depth + 1);

    Wire *host_clk  = CommonPort::get(module, CommonPort::PORT_HOST_CLK);
    Wire *ram_sr    = CommonPort::get(module, CommonPort::PORT_RAM_SR);
    Wire *ram_se    = CommonPort::get(module, CommonPort::PORT_RAM_SE);
    Wire *ram_sd    = CommonPort::get(module, CommonPort::PORT_RAM_SD);
    Wire *ram_li    = CommonPort::get(module, CommonPort::PORT_RAM_LI);
    Wire *ram_lo    = CommonPort::get(module, CommonPort::PORT_RAM_LO);

    make_internal(ram_li);
    make_internal(ram_lo);
    module->fixup_ports();

    // reg [CNTBITS-1:0] in_cnt;
    // wire in_full = in_cnt == DEPTH;
    SigSpec in_cnt = module->addWire(NEW_ID, cntbits);
    SigSpec in_full = module->Eq(NEW_ID, in_cnt, Const(depth, cntbits));

    // always @(posedge clk)
    //     if (ram_sr)
    //         in_cnt <= 0;
    //     else if (ram_se && !in_full)
    //         in_cnt <= in_cnt + 1;
    module->addSdffe(NEW_ID,
        host_clk,
        module->And(NEW_ID, ram_se, module->Not(NEW_ID, in_full)),
        ram_sr,
        module->Add(NEW_ID, in_cnt, Const(1, cntbits)),
        in_cnt,
        Const(0, cntbits));

    // reg out_flag;
    SigSpec out_flag = module->addWire(NEW_ID);

    // always @(posedge clk)
    //     if (ram_sr)
    //         out_flag <= 1'b0;
    //     else if (ram_se)
    //         out_flag <= 1'b1;
    module->addSdffe(NEW_ID,
        host_clk,
        ram_se,
        ram_sr,
        State::S1,
        out_flag,
        State::S0);

    // wire start = ram_sd ? in_full : out_flag;
    // reg start_r;
    SigSpec start = module->Mux(NEW_ID, out_flag, in_full, ram_sd);
    SigSpec start_r = module->addWire(NEW_ID);

    // always @(posedge clk)
    //     if (ram_se)
    //         start_r <= start;
    module->addDffe(NEW_ID,
        host_clk,
        ram_se,
        start,
        start_r);

    // assign ram_li = start && !start_r;
    module->connect(ram_li, module->And(NEW_ID, start, module->Not(NEW_ID, start_r)));
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
        module->attributes.erase(ID::top);
        instrument_module(newmod);

        if (node.index == hier.dag.root)
            tieoff_ram_last(newmod);

        // Rename new module AFTER instrumentation
        newmod->name = newid;
        hier.design->add(newmod);
    }

    for (auto x : all_wire_infos.at(hier.top)) {
        x.first.insert(x.first.begin(), "EMU_TOP");
        database.wire.insert(x);
    }

    for (auto x : all_ram_infos.at(hier.top)) {
        x.first.insert(x.first.begin(), "EMU_TOP");
        database.ram.insert(x);
    }

    for (auto x : ff_lists.at(hier.top)) {
        if (!x.name.empty())
            x.name.insert(x.name.begin(), "EMU_TOP");
        database.scan_ff.push_back(x);
    }

    for (auto x : ram_lists.at(hier.top)) {
        x.name.insert(x.name.begin(), "EMU_TOP");
        database.scan_ram.push_back(x);
    }
}

struct EmuInsertScanchain : public Pass
{
    EmuInsertScanchain() : Pass("emu_insert_scanchain", "(REMU internal)") {}

    void execute(vector<string> args, Design* design) override
    {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_INSERT_SCANCHAIN pass.\n");
        log_push();

        ScanchainWorker worker(design, EmulationDatabase::get_instance(design));
        worker.run();

        log_pop();
    }
} EmuInsertScanchain;

PRIVATE_NAMESPACE_END
