#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "emu.h"
#include "interface.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct ProcessLibWorker {

    Module *module;
    EmulibData &emulib;

    ProcessLibWorker(Module *module, EmulibData &emulib) : module(module), emulib(emulib) {}

    void process_internal_sigs() {
        for (auto &wire : module->selected_wires()) {
            std::string signame = wire->get_string_attribute(AttrIntfPort);
            if (!signame.empty()) {
                promote_intf_port(module, signame, wire);
                wire->attributes.erase(AttrIntfPort);
            }
        }
        module->fixup_ports();
    }

    void run() {
        // check if already processed
        if (module->get_bool_attribute(AttrLibProcessed)) {
            log_warning("Module %s is already processed by emu_process_lib\n", log_id(module));
            return;
        }

        process_internal_sigs();

        for (auto cell : module->cells()) {
            Module *tpl = module->design->module(cell->type);
            if (!tpl)
                continue;

            std::string component = tpl->get_string_attribute(AttrEmulibComponent);
            if (component.empty())
                continue;

            log("Identified cell %s.%s as %s ...\n", log_id(module), log_id(cell), component.c_str());

            // Save attributes

            EmulibCellInfo info;
            info.name = get_hier_name(cell);

            for (auto it : tpl->parameter_default_values)
                info.attrs[it.first.str().substr(1)] = it.second.as_int();

            for (auto it : cell->parameters)
                info.attrs[it.first.str().substr(1)] = it.second.as_int();

            emulib[component].push_back(info);
        }

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
