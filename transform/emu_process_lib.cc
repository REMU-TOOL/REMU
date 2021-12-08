#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

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

struct HandlerContext {
    Module *module;
    Database &db;
    EmulibData &emulib;

    SigSpec ff_clk;
    SigSpec mem_clk;
    SigSpec rst;
    SigSpec trig;

    std::map<std::string, SigSpec> internal_sigs;

    HandlerContext(Module *module, Database &db)
        : module(module), db(db), emulib(db.emulib[module->name]) {}
};

class EmulibHandler {
    static std::map<std::string, EmulibHandler *> handler_map;

public:

    // return true to remove the cell
    virtual bool process_cell(HandlerContext &ctxt, Cell *cell) = 0;
    virtual void process_submodule(HandlerContext &ctxt, Cell *cell, Module *target) = 0;
    virtual void finalize(HandlerContext &ctxt) = 0;

    EmulibHandler(std::string component);

    static EmulibHandler &get(std::string component);
    static void process_submodule_all(HandlerContext &ctxt, Cell *cell, Module *target);
    static void finalize_all(HandlerContext &ctxt);
};

std::map<std::string, EmulibHandler *> EmulibHandler::handler_map;

EmulibHandler::EmulibHandler(std::string component) {
    if (handler_map.find(component) != handler_map.end())
        log_error("EmulibHandler: component %s is already registered\n", component.c_str());

    handler_map[component] = this;
}

EmulibHandler &EmulibHandler::get(std::string component) {
    try {
        return *handler_map.at(component);
    }
    catch (std::out_of_range &x) {
        log_error("EmulibHandler: undefined component %s\n", component.c_str());
    }
}

void EmulibHandler::process_submodule_all(HandlerContext &ctxt, Cell *cell, Module *target) {
    for (auto it : handler_map) {
        it.second->process_submodule(ctxt, cell, target);
    }
}

void EmulibHandler::finalize_all(HandlerContext &ctxt) {
    for (auto it : handler_map) {
        it.second->finalize(ctxt);
    }
}

struct ClockHandler : public EmulibHandler {
    ClockHandler() : EmulibHandler("clock") {}

    virtual bool process_cell(HandlerContext &ctxt, Cell *cell) override {
        Wire *ff_clk = ctxt.module->addWire(NEW_ID);
        Wire *mem_clk = ctxt.module->addWire(NEW_ID);
        SigBit orig_clk = cell->getPort("\\clock")[0];
        rewrite_clock(ctxt.module, orig_clk, ff_clk, mem_clk);
        ctxt.ff_clk.append(ff_clk);
        ctxt.mem_clk.append(mem_clk);

        EmulibCellInfo info;
        info.name = get_hier_name(cell);
        info.attrs["cycle_ps"] = 0; // TODO
        info.attrs["phase_ps"] = 0; // TODO
        ctxt.emulib["clock"].push_back(info);

        return true;
    }

    virtual void process_submodule(HandlerContext &ctxt, Cell *cell, Module *target) override {
        const EmulibData &target_data = ctxt.db.emulib.at(target->name);

        Wire *ff_clk = ctxt.module->addWire(NEW_ID, GetSize(target_data.at("clock")));
        cell->setPort(PortDutFfClk, ff_clk);
        ctxt.ff_clk.append(ff_clk);

        Wire *mem_clk = ctxt.module->addWire(NEW_ID, GetSize(target_data.at("clock")));
        cell->setPort(PortDutRamClk, mem_clk);
        ctxt.mem_clk.append(mem_clk);

        for (auto it : target_data.at("clock")) {
            it.nest(cell);
            ctxt.emulib["clock"].push_back(it);
        }
    }

    virtual void finalize(HandlerContext &ctxt) override {
        Wire *ff_clk_wire = ctxt.module->addWire(PortDutFfClk, GetSize(ctxt.ff_clk));
        ff_clk_wire->port_input = true;
        ctxt.module->connect(ctxt.ff_clk, ff_clk_wire);

        Wire *mem_clk_wire = ctxt.module->addWire(PortDutRamClk, GetSize(ctxt.mem_clk));
        mem_clk_wire->port_input = true;
        ctxt.module->connect(ctxt.mem_clk, mem_clk_wire);

        ctxt.module->fixup_ports();
    }

} ClockHandler;

struct ResetHandler : public EmulibHandler {
    ResetHandler() : EmulibHandler("reset") {}

    virtual bool process_cell(HandlerContext &ctxt, Cell *cell) override {
        ctxt.rst.append(cell->getPort("\\reset"));

        EmulibCellInfo info;
        info.name = get_hier_name(cell);
        info.attrs["duration_ns"] = 0; // TODO
        ctxt.emulib["reset"].push_back(info);

        return true;
    }

    virtual void process_submodule(HandlerContext &ctxt, Cell *cell, Module *target) override {
        EmulibData target_data = ctxt.db.emulib.at(target->name);
        
        Wire *reset = ctxt.module->addWire(NEW_ID, GetSize(target_data.at("reset")));
        cell->setPort(PortDutRst, reset);
        ctxt.rst.append(reset);

        for (auto it : target_data.at("reset")) {
            it.nest(cell);
            ctxt.emulib["reset"].push_back(it);
        }
    }

    virtual void finalize(HandlerContext &ctxt) override {
        Wire *reset_wire = ctxt.module->addWire(PortDutRst, GetSize(ctxt.rst));
        reset_wire->port_input = true;
        ctxt.module->connect(ctxt.rst, reset_wire);
        ctxt.module->fixup_ports();
    }

} ResetHandler;

struct TrigHandler : public EmulibHandler {
    TrigHandler() : EmulibHandler("trigger") {}

    virtual bool process_cell(HandlerContext &ctxt, Cell *cell) override {
        ctxt.trig.append(cell->getPort("\\trigger"));

        EmulibCellInfo info;
        info.name = get_hier_name(cell);
        ctxt.emulib["trigger"].push_back(info);

        return true;
    }

    virtual void process_submodule(HandlerContext &ctxt, Cell *cell, Module *target) override {
        EmulibData target_data = ctxt.db.emulib.at(target->name);

        Wire *trig = ctxt.module->addWire(NEW_ID, GetSize(target_data.at("trigger")));
        cell->setPort(PortDutTrig, trig);
        ctxt.trig.append(trig);

        for (auto it : target_data.at("trigger")) {
            it.nest(cell);
            ctxt.emulib["trigger"].push_back(it);
        }
    }

    virtual void finalize(HandlerContext &ctxt) override {
        Wire *trig_wire = ctxt.module->addWire(PortDutTrig, GetSize(ctxt.trig));
        trig_wire->port_output = true;
        ctxt.module->connect(trig_wire, ctxt.trig);
        ctxt.module->fixup_ports();
    }

} TrigHandler;

struct ModelHandler : public EmulibHandler {
    std::string model;

    ModelHandler(std::string model) : EmulibHandler(model), model(model) {}

    Module *load_model(Design *design, dict<RTLIL::IdString, RTLIL::Const> &parameters) {
        IdString modname = "\\" + model;
        if (design->has(modname))
            design->remove(design->module(modname));

        Design *new_design = new Design;

        log_header(new_design, "Loading model %s ...\n", model.c_str());
        log_push();

        Pass::call(new_design, stringf("read_verilog +/emulib/%s/*.v", model.c_str()));

        log_header(new_design, "Deriving module with given parameters ...\n");
        log_push();

        Module *original_module = new_design->module(modname);
        if (!original_module)
            log_error("Module %s is not found\n", model.c_str());

        IdString derived_modname = original_module->derive(new_design, parameters);
        Module *derived_module = new_design->module(derived_modname);
        derived_module->set_bool_attribute(ID::top);

        log_pop();

        Pass::call(new_design, "hierarchy");
        Pass::call(new_design, "proc");
        Pass::call(new_design, "flatten");
        Pass::call(new_design, "opt");
        Pass::call(new_design, "wreduce");
        Pass::call(new_design, "memory_share");
        Pass::call(new_design, "memory_collect");
        Pass::call(new_design, "opt -fast");
        Pass::call(new_design, "emu_opt_ram");
        Pass::call(new_design, "opt_clean");

        log_pop();

        if (GetSize(new_design->modules()) != 1)
            log_error("Multiple modules detected in model implementation after processing\n");

        Module *top_module = new_design->top_module();
        Module *copy = top_module->clone();
        copy->name = modname;
        copy->design = design;
        copy->attributes.erase(ID::top);
        design->add(copy);

        delete new_design;

        return copy;
    }

    // name -> direction (output=true)
    const dict<std::string, bool> internal_sigs = {
        {"clock",           false},
        {"reset",           false},
        {"pause",           false},
        {"up_req",          false},
        {"down_req",        false},
        {"up_stat",         true},
        {"down_stat",       true},
        {"stall",           true},
        {"dram_awvalid",    true},
        {"dram_awready",    false},
        {"dram_awaddr",     true},
        {"dram_awid",       true},
        {"dram_awlen",      true},
        {"dram_awsize",     true},
        {"dram_awburst",    true},
        {"dram_wvalid",     true},
        {"dram_wready",     false},
        {"dram_wdata",      true},
        {"dram_wstrb",      true},
        {"dram_wlast",      true},
        {"dram_bvalid",     false},
        {"dram_bready",     true},
        {"dram_bid",        false},
        {"dram_arvalid",    true},
        {"dram_arready",    false},
        {"dram_araddr",     true},
        {"dram_arid",       true},
        {"dram_arlen",      true},
        {"dram_arsize",     true},
        {"dram_arburst",    true},
        {"dram_rvalid",     false},
        {"dram_rready",     true},
        {"dram_rdata",      false},
        {"dram_rid",        false},
        {"dram_rlast",      false},
    };

    void process_internal_sigs(Module *module) {
        std::vector<std::pair<Wire *, std::string>> wires;

        for (auto &wire : module->selected_wires()) {
            std::string signame = wire->get_string_attribute(AttrInternalSig);
            if (!signame.empty()) {
                wires.push_back({wire, signame});
            }
        }

        for (auto &it : wires) {
            module->rename(it.first, "\\$EMU$INTERNAL$" + it.second);
            try {
                bool dir = internal_sigs.at(it.second);
                if (dir)
                    it.first->port_output = true;
                else
                    it.first->port_input = true;
            }
            catch (std::out_of_range) {
                log_error("Undefined signal name %s\n", it.second.c_str());
            }
        }

        module->fixup_ports();
    }

    virtual bool process_cell(HandlerContext &ctxt, Cell *cell) override {
        Module *module = ctxt.module;
        Design *design = module->design;

        // Load model implementation
        auto &parameters = cell->parameters;
        Module *model_module = load_model(design, parameters);

        // Flatten this cell
        RTLIL::Selection selection(false);
        selection.select(module, cell);
        Pass::call_on_selection(design, selection, "flatten");
        design->remove(model_module);

        // Process internal signals
        process_internal_sigs(module);

        return false;
    }

    virtual void process_submodule(HandlerContext &ctxt, Cell *cell, Module *target) override {
        // TODO
        static_cast<void>(ctxt);
        static_cast<void>(cell);
        static_cast<void>(target);
    }

    virtual void finalize(HandlerContext &ctxt) override {
        // TODO
        static_cast<void>(ctxt);
    }
};

struct RAMModelHandler : public ModelHandler {
    RAMModelHandler() : ModelHandler("rammodel") {}
} RAMModelHandler;

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

        std::vector<std::pair<Cell *, std::string>> cells;

        for (auto &cell : module->selected_cells()) {
            Module *target = module->design->module(cell->type);

            if (target) {
                std::string component = target->get_string_attribute(AttrEmulibComponent);
                if (!component.empty()) 
                    cells.push_back({cell, component});
            }
        }

        for (auto &it : cells) {
            log("Processing cell %s.%s (%s) ...\n", log_id(module), log_id(it.first), it.second.c_str());
            if (EmulibHandler::get(it.second).process_cell(ctxt, it.first))
                module->remove(it.first);
        }

        // process submodules

        for (auto &cell : module->selected_cells()) {
            Module *target = module->design->module(cell->type);
            if (target && target->get_bool_attribute(AttrLibProcessed)) {
                log("Processing submodule %s.%s (%s) ...\n", log_id(module), log_id(cell), log_id(target));
                EmulibHandler::process_submodule_all(ctxt, cell, target);
            }
        }

        // add ports & connect signals

        EmulibHandler::finalize_all(ctxt);

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
            ProcessLibWorker worker(mod, db);
            worker.run();
        }

        log_pop();
    }
} EmuProcessLibPass;

PRIVATE_NAMESPACE_END
