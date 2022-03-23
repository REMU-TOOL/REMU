#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"
#include "interface.h"
#include "designtools.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE

namespace Emu {
namespace Interface {

enum IntfProp {
    InputShare          = 0x0,
    InputAppend         = 0x1,
    InputAutoIndex      = 0x2,
    OutputAppend        = 0x10000,
    OutputAndReduce     = 0x10001,
    OutputOrReduce      = 0x10002,
    OutputAutoIndex     = 0x10003,
};

inline bool is_output(IntfProp prop) {
    return prop & 0x10000;
}

// name -> direction (output=true)
const std::map<std::string, IntfProp> intf_list = {
    {"host_clk",        InputShare},
    {"host_rst",        InputShare},
    {"ff_se",           InputShare},
    {"ff_di",           InputShare},
    {"ff_do",           OutputAppend},
    {"ram_se",          InputShare},
    {"ram_sd",          InputShare},
    {"ram_di",          InputShare},
    {"ram_do",          OutputAppend},
    {"ram_li",          InputShare},
    {"ram_lo",          OutputAppend},
    {"target_fire",     InputShare},
    {"stall",           OutputOrReduce},
    {"up_req",          InputShare},
    {"down_req",        InputShare},
    {"up_stat",         OutputAndReduce},
    {"down_stat",       OutputAndReduce},
    {"dut_ff_clk",      InputAppend},
    {"dut_ram_clk",     InputAppend},
    {"dut_rst",         InputAppend},
    {"dut_trig",        OutputAppend},
    {"putchar_valid",   OutputAppend},
    {"putchar_ready",   InputAppend},
    {"putchar_data",    OutputAppend},
};

static inline IdString get_count_attr(std::string name) {
    return "\\EmuIntfPortCnt_" + name;
}

static inline IdString get_internal_id(std::string name, int index) {
    return stringf("\\emu_internal_%s_%d", name.c_str(), index);
}

void promote_intf_port(Module *module, std::string name, Wire *wire) {
    int count = 0;
    IdString count_attr = get_count_attr(name);

    if (module->has_attribute(count_attr))
        count = module->attributes.at(count_attr).as_int();

    module->rename(wire, get_internal_id(name, count++));

    try {
        if (is_output(intf_list.at(name)))
            wire->port_output = true;
        else
            wire->port_input = true;
    }
    catch (std::out_of_range const&) {
        log_error("Unknown interface name %s\n", name.c_str());
    }

    module->attributes[count_attr] = Const(count);
}

Wire *create_intf_port(Module *module, std::string name, int width) {
    Wire *port = module->addWire(NEW_ID, width);
    promote_intf_port(module, name, port);
    return port;
}

std::vector<Wire *> get_intf_ports(Module *module, std::string name) {
    int count = 0;
    IdString count_attr = get_count_attr(name);

    if (module->has_attribute(count_attr))
        count = module->attributes.at(count_attr).as_int();

    std::vector<Wire *> port_list;

    for (int i = 0; i < count; i++)
        port_list.push_back(module->wire(get_internal_id(name.c_str(), i)));

    return port_list;
}

void unregister_intf_ports(Module *module, std::string name) {
    int count = 0;
    IdString count_attr = get_count_attr(name);

    if (module->has_attribute(count_attr))
        count = module->attributes.at(count_attr).as_int();

    module->attributes.erase(count_attr);

    for (int i = 0; i < count; i++) {
        Wire *wire = module->wire(get_internal_id(name.c_str(), i));
        module->rename(wire, "$unregistered" + wire->name.str());
        wire->port_input = false;
        wire->port_output = false;
    }
}

} // namespace Interface
} // namespace Emu

PRIVATE_NAMESPACE_BEGIN

struct RenameModuleWorker {
    Design *design;
    DesignWalker walker;

    bool rename(Module *module, IdString new_name) {
        if (design->has(new_name))
            return false;

        design->rename(module, new_name);

        for (auto cell : walker.instances_of(module)) {
            cell->type = new_name;
        }

        return true;
    }

    RenameModuleWorker(Design *design) : design(design), walker(design) {}
};

struct ProcessLibWorker {

    Design *design;
    Database &database;

    ProcessLibWorker(Design *design, Database &database) : design(design), database(database) {}

    void promote_mod_intf_ports(Module *module) {
        for (auto &wire : module->selected_wires()) {
            std::string signame = wire->get_string_attribute(AttrIntfPort);
            if (!signame.empty()) {
                promote_intf_port(module, signame, wire);
                wire->attributes.erase(AttrIntfPort);
            }
        }
    }

    void propagate_submodule(Cell *cell) {
        Module* module = cell->module;
        Module *target = design->module(cell->type);
        EmulibData &emulib = database.emulib[module->name];
        ScanChainData &sc = database.scanchain[module->name];

        // promote submodule interfaces
        for (auto it : intf_list) {
            std::vector<Wire *> target_wires = get_intf_ports(target, it.first);
            if (it.first != "ff_di" && it.first != "ff_do" &&
                it.first != "ram_di" && it.first != "ram_do" &&
                it.first != "ram_li" && it.first != "ram_lo") {
                for (auto target_wire : target_wires) {
                    Wire *wire = module->addWire(NEW_ID, target_wire);
                    cell->setPort(target_wire->name, wire);
                    promote_intf_port(module, it.first, wire);
                }
            }
        }

        // connect submodule scanchain

        auto module_ff_di = get_intf_ports(module, "ff_di");
        auto module_ram_di = get_intf_ports(module, "ram_di");
        auto module_ram_lo = get_intf_ports(module, "ram_lo");
        auto target_ff_di = get_intf_ports(target, "ff_di");
        auto target_ff_do = get_intf_ports(target, "ff_do");
        auto target_ram_di = get_intf_ports(target, "ram_di");
        auto target_ram_do = get_intf_ports(target, "ram_do");
        auto target_ram_li = get_intf_ports(target, "ram_li");
        auto target_ram_lo = get_intf_ports(target, "ram_lo");

        log_assert(GetSize(module_ff_di) == 1);
        log_assert(GetSize(module_ram_di) == 1);
        log_assert(GetSize(module_ram_lo) == 1);
        log_assert(GetSize(target_ff_di) == 1);
        log_assert(GetSize(target_ff_do) == 1);
        log_assert(GetSize(target_ram_di) == 1);
        log_assert(GetSize(target_ram_do) == 1);
        log_assert(GetSize(target_ram_li) == 1);
        log_assert(GetSize(target_ram_lo) == 1);

        IdString ff_di_name = module_ff_di[0]->name;
        IdString ram_di_name = module_ram_di[0]->name;
        IdString ram_lo_name = module_ram_lo[0]->name;
        module->rename(module_ff_di[0], NEW_ID);
        module->rename(module_ram_di[0], NEW_ID);
        module->rename(module_ram_lo[0], NEW_ID);
        Wire *new_ff_di = module->addWire(ff_di_name, module_ff_di[0]);
        Wire *new_ram_di = module->addWire(ram_di_name, module_ram_di[0]);
        Wire *new_ram_lo = module->addWire(ram_lo_name, module_ram_lo[0]);
        module_ff_di[0]->port_input = false;
        module_ram_di[0]->port_input = false;
        module_ram_lo[0]->port_output = false;

        cell->setPort(target_ff_di[0]->name, new_ff_di);
        cell->setPort(target_ram_di[0]->name, new_ram_di);
        cell->setPort(target_ram_li[0]->name, module_ram_lo[0]);
        cell->setPort(target_ff_do[0]->name, module_ff_di[0]);
        cell->setPort(target_ram_do[0]->name, module_ram_di[0]);
        cell->setPort(target_ram_lo[0]->name, new_ram_lo);

        // import submodule model data
        for (auto it : database.emulib[target->name]) {
            auto &this_data = emulib[it.first];
            for (auto &data : it.second)
                this_data.push_back(data.nest(cell));
        }

        // import submodule scanchain data
        auto target_sc = database.scanchain[target->name];
        for (auto &ff : target_sc.ff)
            sc.ff.push_back(ff.nest(cell));
        for (auto &mem : target_sc.mem)
            sc.mem.push_back(mem.nest(cell));
    }

    void process_module(Module *module) {
        // Process submodules

        for (auto cell : module->cells())
            if (design->has(cell->type))
                propagate_submodule(cell);

        module->fixup_ports();
    }

    // Promote interfaces & import databases from child modules to parent modules
    void run() {
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
            log("Processing module %s\n", log_id(mod));
            process_module(mod);
        }
    }

};

struct PackageWorker {

    Database &database;
    Design *design;

    void process_intf_ports(Module *module) {
        for (auto &it : intf_list) {
            int count = 0;
            IdString count_attr = get_count_attr(it.first);

            if (module->has_attribute(count_attr))
                count = module->attributes.at(count_attr).as_int();

            if (it.second == InputAutoIndex || it.second == OutputAutoIndex) {
                for (int i = 0; i < count; i++) {
                    Wire *wire = module->wire(get_internal_id(it.first.c_str(), i));
                    module->rename(wire, stringf("\\emu_auto_%d_%s", i, it.first.c_str()));
                }
                continue;
            }

            IdString wirename = "\\emu_" + it.first;
            std::vector<Wire *> wire_list;

            for (int i = 0; i < count; i++) {
                Wire *wire = module->wire(get_internal_id(it.first.c_str(), i));
                wire->port_input = false;
                wire->port_output = false;
                wire_list.push_back(wire);
            }

            if (it.second == InputShare) {
                int width = 0;
                if (!wire_list.empty())
                    width = wire_list[0]->width;

                Wire *port = module->addWire(wirename, width);
                port->port_input = true;

                for (Wire *wire : wire_list) {
                    if (wire->width != port->width)
                        log_error("Shared interface port %s has different widths (current %d, first %d)\n",
                            it.first.c_str(), wire->width, port->width);

                    module->connect(wire, port);
                }

                continue;
            }

            SigSpec flat_sig;
            for (Wire *wire : wire_list)
                flat_sig.append(wire);

            if (it.second == OutputAndReduce)
                flat_sig = module->ReduceAnd(NEW_ID, flat_sig);
            else if (it.second == OutputOrReduce)
                flat_sig = module->ReduceOr(NEW_ID, flat_sig);

            Wire *port = module->addWire(wirename, GetSize(flat_sig));
            if (is_output(it.second)) {
                port->port_output = true;
                module->connect(port, flat_sig);
            }
            else {
                port->port_input = true;
                module->connect(flat_sig, port);
            }
        }

        module->fixup_ports();
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
    
    void add_controller(Module *module) {
        std::string share_dirname = proc_share_dirname();
        std::vector<std::string> read_verilog_argv = {
            "read_verilog",
            "-lib",
            "-I",
            share_dirname + "emulib/include",
            share_dirname + "emulib/rtl/emu_controller.v"
        };

        Pass::call(design, read_verilog_argv);

        IdString ctrl_id = "\\emu_controller";
        Module *ctrl_mod = design->module(ctrl_id);
        Cell *ctrl_cell = module->addCell(module->uniquify("\\controller"), ctrl_id);

        ScanChainData & sc = database.scanchain[database.top];

        ctrl_cell->setParam("\\CHAIN_FF_WORDS", Const(GetSize(sc.ff)));

        int words = 0;
        for (auto &mem : sc.mem)
            words += mem.depth;
        ctrl_cell->setParam("\\CHAIN_MEM_WORDS", Const(words));

        for (auto id : ctrl_mod->ports) {
            Wire *port = module->wire(id);
            if (port) {
                // Connect existing ports to controller
                port->port_input = false;
                port->port_output = false;
                ctrl_cell->setPort(id, port);
            }
            else {
                // Expose controller-owned ports
                port = module->addWire(id, ctrl_mod->wire(id));
                ctrl_cell->setPort(id, port);
            }
        }

        module->fixup_ports();
    }

    void run() {
        Module *dut_top = design->top_module();

        if (!dut_top)
            log_error("No top module found\n");

        database.top = dut_top->name;

        // Create interface ports
        process_intf_ports(dut_top);

        // Fix up ports
        ScanChainData &sc = database.scanchain.at(database.top);
        Wire *clk = dut_top->wire("\\emu_host_clk");
        Wire *ram_se = dut_top->wire("\\emu_ram_se");
        Wire *ram_sd = dut_top->wire("\\emu_ram_sd");
        Wire *ram_li = dut_top->wire("\\emu_ram_li");
        Wire *ram_lo = dut_top->wire("\\emu_ram_lo");
        ram_li->port_input = false;
        ram_lo->port_output = false;
        dut_top->fixup_ports();
        generate_mem_last_i(dut_top, sc.mem_sc_depth(), clk, ram_se, ram_sd, ram_li);

        // Rename modules

        RenameModuleWorker rmworker(design);
        for (auto module : design->modules().to_vector()) {
            std::string name_str = module->name.str();
            IdString new_name = "\\EMU_PACKAGE_" + (name_str[0] == '\\' ? name_str.substr(1) : name_str);
            rmworker.rename(module, new_name);
        }

        // Rename DUT
        design->rename(dut_top, "\\EMU_DUT");
        dut_top->attributes.erase(ID::top);

        // Create new top module
        Module *new_top = design->addModule("\\EMU_SYSTEM");
        new_top->set_bool_attribute(ID::top);

        // Instantiate DUT
        Cell *dut_cell = new_top->addCell("\\dut", dut_top->name);
        for (auto id : dut_top->ports) {
            Wire *port = new_top->addWire(id, dut_top->wire(id));
            dut_cell->setPort(id, port);
        }

        // Instantiate controller module
        add_controller(new_top);
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
        log_push();

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

        ProcessLibWorker lib_worker(design, db);
        lib_worker.run();

        PackageWorker pkg_worker(db, design);
        pkg_worker.run();

        log_pop();
    }
} EmuPackagePass;

PRIVATE_NAMESPACE_END
