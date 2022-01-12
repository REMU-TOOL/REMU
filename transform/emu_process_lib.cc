#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "emu.h"
#include "interface.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct HandlerContext {
    Module *module;
    EmulibData &emulib;

    HandlerContext(Module *module, EmulibData &emulib)
        : module(module), emulib(emulib) {}
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
        std::string signame = wire->get_string_attribute(AttrIntfPort);
        if (!signame.empty()) {
            promote_intf_port(module, signame, wire);
            wire->attributes.erase(AttrIntfPort);
        }
    }
    module->fixup_ports();
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
    for (auto it : handler_map)
        it.second->do_finalize(ctxt);
}

struct ClockHandler : public ModelHandler {
    ClockHandler() : ModelHandler("clock") {}
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
    EmulibData &emulib;

    ProcessLibWorker(Module *module, EmulibData &emulib) : module(module), emulib(emulib) {}

    void run() {
        // check if already processed
        if (module->get_bool_attribute(AttrLibProcessed)) {
            log_warning("Module %s is already processed by emu_process_lib\n", log_id(module));
            return;
        }

        HandlerContext ctxt(module, emulib);

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

        for (auto mod : design->selected_modules()) {
            log("Processing module %s\n", mod->name.c_str());
            ProcessLibWorker worker(mod, db.emulib[mod->name]);
            worker.run();
        }

        log_pop();
    }
} EmuProcessLibPass;

PRIVATE_NAMESPACE_END
