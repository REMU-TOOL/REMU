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

    ProcessLibWorker(Design *design) : design(design) {}

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

        // promote submodule interfaces
        for (auto it : intf_list) {
            std::vector<Wire *> target_wires = get_intf_ports(target, it.first);
            for (auto target_wire : target_wires) {
                Wire *wire = module->addWire(NEW_ID, target_wire);
                cell->setPort(target_wire->name, wire);
                promote_intf_port(module, it.first, wire);
            }
        }
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
    
    void add_controller(Module *module, int ff_words, int mem_words) {
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

        ctrl_cell->setParam("\\CHAIN_FF_WORDS", Const(ff_words));
        ctrl_cell->setParam("\\CHAIN_MEM_WORDS", Const(mem_words));

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

        // Create interface ports
        process_intf_ports(dut_top);

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

        int ff_words = dut_top->attributes.at("\\emu_sc_ff_count").as_int();
        int mem_words = dut_top->attributes.at("\\emu_sc_ram_count").as_int();

        // Instantiate controller module
        add_controller(new_top, ff_words, mem_words);
    }

    PackageWorker(Design *design) : design(design) {}

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
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PACKAGE pass.\n");
        log_push();

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            break;
        }
        extra_args(args, argidx, design);

        ProcessLibWorker lib_worker(design);
        lib_worker.run();

        PackageWorker pkg_worker(design);
        pkg_worker.run();

        log_pop();
    }
} EmuPackagePass;

PRIVATE_NAMESPACE_END
