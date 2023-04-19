#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuFixupPortConn : public Pass {
    EmuFixupPortConn() : Pass("emu_fixup_port_conn", "fix up port connections") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_fixup_port_conn [selection]\n");
        log("\n");
        log("This command fix up unconnected input ports.\n");
    }

    std::string top_name;

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_FIXUP_PORT_CONN pass.\n");
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

                    log("Fix up unconnected port %s.%s\n", log_id(cell), log_id(id));
                    cell->setPort(id, Const(0, GetSize(tpl_wire)));
                }
            }
        }

        log_pop();
    }

} EmuFixupPortConn;

PRIVATE_NAMESPACE_END
