#include "kernel/yosys.h"
#include "kernel/modtools.h"

#include "utils.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN



struct EmuFixupDriver : public Pass {
    EmuFixupDriver() : Pass("emu_fixup_driver", "fix up undriven wires") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_fixup_driver [selection]\n");
        log("\n");
        log("This command fix up undriven wires/ports.\n");
    }

    std::string top_name;

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_FIXUP_DRIVER pass.\n");
        log_push();

        std::vector<std::string> mod_names;
        std::vector<IdString> mod_attrs;

		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			break;
		}
		extra_args(args, argidx, design);

        for (auto module : design->selected_modules()) {
            log("Processing module %s\n", module->name.c_str());

            ModWalker modwalker(design, module);
            SigSpec wires_to_fixup;

            for (auto wire : module->selected_wires()) {
                if (wire->port_input)
                    continue;

                for (auto b : modwalker.sigmap(wire)) {
                    if (!b.is_wire())
                        continue;

                    if (modwalker.has_inputs(SigSpec(b)))
                        continue;

                    if (modwalker.has_drivers(SigSpec(b)))
                        continue;

                    wires_to_fixup.append(b);
                }
            }

            if (!wires_to_fixup.empty()) {
                wires_to_fixup.sort_and_unify();

                log("Fix up undriven wire ");
                for (auto chunk : wires_to_fixup.chunks())
                    log("%s ", pretty_name(chunk).c_str());
                log("\n");

                module->connect(wires_to_fixup, Const(0, GetSize(wires_to_fixup)));
            }

            for (auto cell : module->selected_cells()) {
                Module *tpl = design->module(cell->type);
                if (!tpl)
                    continue;

                for (auto id : tpl->ports) {
                    if (cell->connections_.count(id) > 0)
                        continue;

                    Wire *tpl_wire = tpl->wire(id);
                    if (tpl_wire->port_output)
                        continue;

                    log("Fix up undriven port %s.%s\n", log_id(cell), log_id(id));
                    cell->setPort(id, Const(0, GetSize(tpl_wire)));
                }
            }
        }

        log_pop();
    }

} EmuFixupDriver;

PRIVATE_NAMESPACE_END
