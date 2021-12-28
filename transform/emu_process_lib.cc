#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct HandlerContext {
    Module *module;
    Database &db;
    EmulibData &emulib;

    std::map<std::string, std::vector<SigSpec>> internal_sigs;

    HandlerContext(Module *module, Database &db)
        : module(module), db(db), emulib(db.emulib) {}
};

enum InternalSigProp {
    InputAppend,
    InputShare,
    InputAutoIndex,
    OutputAppend,
    OutputAndReduce,
    OutputOrReduce,
    OutputAutoIndex,
};

// name -> direction (output=true)
const dict<std::string, InternalSigProp> internal_sig_list = {
    {"CLOCK",           InputShare},
    {"RESET",           InputShare},
    {"PAUSE",           InputShare},
    {"UP_REQ",          InputShare},
    {"DOWN_REQ",        InputShare},
    {"UP_STAT",         OutputAndReduce},
    {"DOWN_STAT",       OutputAndReduce},
    {"STALL",           OutputOrReduce},
    {"DUT_FF_CLK",      InputAppend},
    {"DUT_RAM_CLK",     InputAppend},
    {"DUT_RST",         InputAppend},
    {"DUT_TRIG",        OutputAppend},
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

struct ModelHandler {
    static std::map<std::string, ModelHandler *> handler_map;

    ModelHandler(std::string component) {
        if (handler_map.find(component) != handler_map.end())
            log_error("ModelHandler: component %s is already registered\n", component.c_str());

        handler_map[component] = this;
    }

    virtual void do_handle(HandlerContext &ctxt, Cell *cell) {
        static_cast<void>(ctxt);
        static_cast<void>(cell);
    }

    virtual void do_finalize(HandlerContext &ctxt) {
        static_cast<void>(ctxt);
    }

    static void handle(HandlerContext &ctxt, Cell *cell);
    static void finalize(HandlerContext &ctxt);
};

std::map<std::string, ModelHandler *> ModelHandler::handler_map;

void load_model(HandlerContext &ctxt, Cell *cell) {
    Module *module = cell->module;
    Design *design = module->design;
    Module *stub = design->module(cell->type);
    std::string model = stub->get_string_attribute(AttrEmulibComponent);

    // Save attributes

    EmulibCellInfo info;
    info.name = get_hier_name(cell);

    for (auto it : stub->parameter_default_values)
        info.attrs[it.first.str().substr(1)] = it.second.as_int();

    for (auto it : cell->parameters)
        info.attrs[it.first.str().substr(1)] = it.second.as_int();

    ctxt.emulib[model].push_back(info);

    // Load & process model design

    Design *new_design = new Design;

    std::string share_dirname = proc_share_dirname();
    std::vector<std::string> read_verilog_argv = {
        "read_verilog",
        "-I",
        share_dirname + "emulib/include",
        share_dirname + "emulib/model/" + model + "/*.v"
    };

    Pass::call(new_design, read_verilog_argv);

    Module *original_module = new_design->module("\\" + model);
    if (!original_module)
        log_error("Module %s is not found\n", model.c_str());

    IdString derived_modname = original_module->derive(new_design, cell->parameters);
    Module *derived_module = new_design->module(derived_modname);
    derived_module->set_bool_attribute(ID::top);

    Pass::call(new_design, "hierarchy");
    Pass::call(new_design, "proc");
    Pass::call(new_design, "emu_prop_attr -a emu_no_scanchain");
    Pass::call(new_design, "flatten");
    Pass::call(new_design, "opt");
    Pass::call(new_design, "wreduce");
    Pass::call(new_design, "memory_share");
    Pass::call(new_design, "memory_collect");
    Pass::call(new_design, "opt -fast");
    Pass::call(new_design, "emu_opt_ram");
    Pass::call(new_design, "opt_clean");

    if (GetSize(new_design->modules()) != 1)
        log_error("Multiple modules detected in model implementation after processing\n");

    design->remove(stub);

    Module *top_module = new_design->top_module();
    Module *copy = top_module->clone();
    copy->name = cell->type;
    copy->design = design;
    copy->attributes.erase(ID::top);
    design->add(copy);

    for (auto cell : copy->cells()) {
        cell->set_bool_attribute(AttrModel);
    }

    for (auto wire : copy->wires()) {
        wire->set_bool_attribute(AttrModel);
    }

    delete new_design;

    // Flatten this cell
    RTLIL::Selection selection(false);
    selection.select(module, cell);
    Pass::call_on_selection(design, selection, "flatten");
    design->remove(copy);

    // Process internal signals
    for (auto &wire : module->selected_wires()) {
        std::string signame = wire->get_string_attribute(AttrInternalSig);
        if (!signame.empty()) {
            if (internal_sig_list.find(signame) == internal_sig_list.end())
                log_error("Undefined signal name %s\n", signame.c_str());
            ctxt.internal_sigs[signame].push_back(wire);
            wire->attributes.erase(AttrInternalSig);
        }
    }
}

void ModelHandler::handle(HandlerContext &ctxt, Cell *cell) {
    Module *target = ctxt.module->design->module(cell->type);

    if (!target)
        return;

    std::string component = target->get_string_attribute(AttrEmulibComponent);
    if (component.empty())
        return;

    log_header(ctxt.module->design, "Processing cell %s.%s (%s) ...\n", log_id(ctxt.module), log_id(cell), component.c_str());
    log_push();

    ModelHandler *handler = nullptr;
    try {
        handler = handler_map.at(component);
    }
    catch (std::out_of_range &x) {
        log_error("ModelHandler: undefined component %s\n", component.c_str());
    }

    handler->do_handle(ctxt, cell);

    load_model(ctxt, cell);

    log_pop();
}

void ModelHandler::finalize(HandlerContext &ctxt) {
    for (auto &it : internal_sig_list) {
        Wire *wire = nullptr;
        const auto &sigs = ctxt.internal_sigs[it.first];

        if (it.second == InputAutoIndex || it.second == OutputAutoIndex) {
            int index = 0;
            bool output = it.second == OutputAutoIndex;
            for (auto &s : sigs) {
                IdString wirename = stringf("\\EMU_AUTO_%d_", index++) + it.first;
                wire = emu_create_port(ctxt.module, wirename, GetSize(s), output);
                if (output)
                    ctxt.module->connect(wire, s);
                else
                    ctxt.module->connect(s, wire);
            }
            continue;
        }

        IdString wirename = "\\EMU_" + it.first;
        SigSpec flat_sig;
        for (auto &s : sigs)
            flat_sig.append(s);

        switch (it.second) {
            case InputAppend:
                wire = emu_create_port(ctxt.module, wirename, GetSize(flat_sig), false);
                ctxt.module->connect(flat_sig, wire);
                break;
            case InputShare:
                wire = emu_create_port(ctxt.module, wirename, 1, false);
                for (SigBit &bit : flat_sig)
                    ctxt.module->connect(bit, wire);
                break;
            case OutputAppend:
                wire = emu_create_port(ctxt.module, wirename, GetSize(flat_sig), true);
                ctxt.module->connect(wire, flat_sig);
                break;
            case OutputAndReduce:
                flat_sig.append(State::S1);
                wire = emu_create_port(ctxt.module, wirename, 1, true);
                ctxt.module->connect(wire, ctxt.module->ReduceAnd(NEW_ID, flat_sig));
                break;
            case OutputOrReduce:
                flat_sig.append(State::S0);
                wire = emu_create_port(ctxt.module, wirename, 1, true);
                ctxt.module->connect(wire, ctxt.module->ReduceOr(NEW_ID, flat_sig));
                break;
            default:
                break;
        }
    }

    ctxt.module->fixup_ports();

    for (auto it : handler_map)
        it.second->do_finalize(ctxt);
}

struct ClockHandler : public ModelHandler {
    ClockHandler() : ModelHandler("clock") {}

    void replace_portbit(ModWalker::PortBit &portbit, SigBit &newbit) {
        SigSpec new_port = portbit.cell->getPort(portbit.port);
        new_port[portbit.offset] = newbit;
        portbit.cell->setPort(portbit.port, new_port);
    }

    // Rewrite module to assign FFs & Mems with separated ff_clk & mem_clk
    void rewrite_clock(Module *module, SigBit orig_clk, SigBit ff_clk, SigBit mem_clk) {
        ModWalker modwalker(module->design, module);

        pool<ModWalker::PortBit> portbits;
        modwalker.get_consumers(portbits, SigSpec(orig_clk)); // Workaround: the SigBit-version get_consumers is now inaccessible
        for (auto &portbit : portbits) {
            if (RTLIL::builtin_ff_cell_types().count(portbit.cell->type)) {
                replace_portbit(portbit, ff_clk);
            }
            else if (portbit.cell->is_mem_cell()) {
                replace_portbit(portbit, mem_clk);
            }
            else {
                Module *target = module->design->module(portbit.cell->type);

                if (!target)
                    log_error("Unknown cell type cannot be handled by rewrite_clock: %s\n",
                        portbit.cell->type.c_str());

                // Rewrite submodule
                Wire *target_port = target->wire(portbit.port);
                std::string new_name = target_port->name.str() + "$EMU$ADDED$PORT";
                if (!target_port->has_attribute(AttrClkPortRewritten)) {
                    Wire *new_port = target->addWire(new_name);
                    new_port->port_input = true;
                    target->fixup_ports();

                    SigBit target_ff_clk = SigSpec(target_port)[portbit.offset];
                    rewrite_clock(target, target_ff_clk, target_ff_clk, new_port);

                    target_port->set_bool_attribute(AttrClkPortRewritten);
                }

                replace_portbit(portbit, ff_clk);
                portbit.cell->setPort(new_name, mem_clk);
            }
        }
    }

    virtual void do_handle(HandlerContext &ctxt, Cell *cell) override {
        cell->setPort("\\ram_clock", ctxt.module->addWire(NEW_ID));
    }

    virtual void do_finalize(HandlerContext &ctxt) override {
        auto &fclks = ctxt.internal_sigs["DUT_FF_CLK"];
        auto &rclks = ctxt.internal_sigs["DUT_RAM_CLK"];
        for (
            auto fclk = fclks.begin(), rclk = rclks.begin();
            fclk != fclks.end() && rclk != rclks.end();
            ++fclk, ++rclk
        ) {
            rewrite_clock(ctxt.module, *fclk, *fclk, *rclk);
        }
    }

} ClockHandler;

struct ResetHandler : public ModelHandler {
    ResetHandler() : ModelHandler("reset") {}
} ResetHandler;

struct TrigHandler : public ModelHandler {
    TrigHandler() : ModelHandler("trigger") {}
} TrigHandler;

struct RAMModelHandler : public ModelHandler {
    RAMModelHandler() : ModelHandler("rammodel") {}
} RAMModelHandler;

struct PutCharHandler : public ModelHandler {
    PutCharHandler() : ModelHandler("putchar") {}
} PutCharHandler;

struct ProcessLibWorker {

    Module *module;
    Database &db;

    ProcessLibWorker(Module *module, Database &db) : module(module), db(db) {}

    void run() {
        // check if already processed
        if (module->get_bool_attribute(AttrLibProcessed)) {
            log_warning("Module %s is already processed by emu_process_lib\n", log_id(module));
            return;
        }

        HandlerContext ctxt(module, db);

        for (auto &cell : module->selected_cells())
            ModelHandler::handle(ctxt, cell);

        ModelHandler::finalize(ctxt);

        module->set_bool_attribute(AttrLibProcessed);
    }

};

struct EmuProcessLibPass : public Pass {
    EmuProcessLibPass() : Pass("emu_process_lib", "process emulation libraries in design") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_process_lib [options]\n");
        log("\n");
        log("This command replaces emulation libraries in the design with emulation logic.\n");
        log("\n");
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PROCESS_LIB pass.\n");
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

        Module *top = design->top_module();
		if (!top)
			log_error("No top module found.\n");

        log("Processing module %s\n", top->name.c_str());
        ProcessLibWorker worker(top, db);
        worker.run();

        log_pop();
    }
} EmuProcessLibPass;

PRIVATE_NAMESPACE_END
