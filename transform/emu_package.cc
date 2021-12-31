#include "kernel/yosys.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

namespace Emu {

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
    {"clk",             InputShare},
    {"rst",             InputShare},
    {"ff_se",           InputShare},
    {"ff_di",           InputShare},
    {"ff_do",           OutputAppend},
    {"ram_se",          InputShare},
    {"ram_sd",          InputShare},
    {"ram_di",          InputShare},
    {"ram_do",          OutputAppend},
    {"pause",           InputShare},
    {"up_req",          InputShare},
    {"down_req",        InputShare},
    {"up_stat",         OutputAndReduce},
    {"down_stat",       OutputAndReduce},
    {"stall",           OutputOrReduce},
    {"dut_ff_clk",      InputAppend},
    {"dut_ram_clk",     InputAppend},
    {"dut_rst",         InputAppend},
    {"dut_trig",        OutputAppend},
    {"dram_awvalid",    OutputAutoIndex},
    {"dram_awready",    InputAutoIndex},
    {"dram_awaddr",     OutputAutoIndex},
    {"dram_awid",       OutputAutoIndex},
    {"dram_awlen",      OutputAutoIndex},
    {"dram_awsize",     OutputAutoIndex},
    {"dram_awburst",    OutputAutoIndex},
    {"dram_awlock",     OutputAutoIndex},
    {"dram_awcache",    OutputAutoIndex},
    {"dram_awprot",     OutputAutoIndex},
    {"dram_awqos",      OutputAutoIndex},
    {"dram_awregion",   OutputAutoIndex},
    {"dram_wvalid",     OutputAutoIndex},
    {"dram_wready",     InputAutoIndex},
    {"dram_wdata",      OutputAutoIndex},
    {"dram_wstrb",      OutputAutoIndex},
    {"dram_wlast",      OutputAutoIndex},
    {"dram_bvalid",     InputAutoIndex},
    {"dram_bready",     OutputAutoIndex},
    {"dram_bresp",      InputAutoIndex},
    {"dram_bid",        InputAutoIndex},
    {"dram_arvalid",    OutputAutoIndex},
    {"dram_arready",    InputAutoIndex},
    {"dram_araddr",     OutputAutoIndex},
    {"dram_arid",       OutputAutoIndex},
    {"dram_arlen",      OutputAutoIndex},
    {"dram_arsize",     OutputAutoIndex},
    {"dram_arburst",    OutputAutoIndex},
    {"dram_arlock",     OutputAutoIndex},
    {"dram_arcache",    OutputAutoIndex},
    {"dram_arprot",     OutputAutoIndex},
    {"dram_arqos",      OutputAutoIndex},
    {"dram_arregion",   OutputAutoIndex},
    {"dram_rvalid",     InputAutoIndex},
    {"dram_rready",     OutputAutoIndex},
    {"dram_rdata",      InputAutoIndex},
    {"dram_rresp",      InputAutoIndex},
    {"dram_rid",        InputAutoIndex},
    {"dram_rlast",      InputAutoIndex},
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
    catch (std::out_of_range) {
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

}

PRIVATE_NAMESPACE_BEGIN

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

    void run(bool bare) {
        Module *top = design->top_module();

        if (!top)
            log_error("No top module found\n");

        if (!top->get_bool_attribute(AttrLibProcessed))
            log_error("Module %s is not processed by emu_process_lib. Run emu_process_lib first.\n", log_id(top));

        if (!top->get_bool_attribute(AttrInstrumented))
            log_error("Module %s is not processed by emu_instrument. Run emu_instrument first.\n", log_id(top));

        design->rename(top, "\\EMU_DUT");

        process_intf_ports(top);

        if (bare)
            return;
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
        log("    -bare\n");
        log("        expose scan chain interface and do not include controller.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PACKAGE pass.\n");

        std::string db_name;
        bool bare = false;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-db" && argidx+1 < args.size()) {
                db_name = args[++argidx];
                continue;
            }
            if (args[argidx] == "-bare") {
                bare = true;
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        Database &db = Database::databases[db_name];

        PackageWorker worker(db, design);
        worker.run(bare);
    }
} EmuPackagePass;

PRIVATE_NAMESPACE_END
