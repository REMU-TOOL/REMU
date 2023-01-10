#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuRestoreParamCells : public Pass {
    EmuRestoreParamCells() : Pass("emu_restore_param_cells", "restore instances of parameterized modules") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_restore_param_cells [options] [selection]\n");
        log("\n");
        log("This command restores cells of parameterized modules to original instantiations.\n");
        log("The type and parameters of involved cells will be restored.\n");
        log("\n");
        log("    -mod-name <name>\n");
        log("        match parameterized modules with this original name (hdlname attribute)\n");
        log("    -mod-attr <attr>\n");
        log("        match parameterized modules which have this attribute set\n");
        log("\n");
    }

    std::string top_name;

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_RESTORE_PARAM_CELLS pass.\n");
        log_push();

        std::vector<std::string> mod_names;
        std::vector<IdString> mod_attrs;

		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-mod-name") {
				mod_names.push_back("\\" + args[++argidx]);
				continue;
			}
			if (args[argidx] == "-mod-attr") {
				mod_attrs.push_back("\\" + args[++argidx]);
				continue;
			}
			break;
		}
		extra_args(args, argidx, design);

        pool<IdString> matched_mods;

        for (auto module : design->modules()) {
            if (!module->has_attribute(ID::hdlname))
                continue;
            for (auto name : mod_names)
                if (module->get_string_attribute(ID::hdlname) == name)
                    matched_mods.insert(module->name);
            for (auto attr : mod_attrs)
                if (module->has_attribute(attr))
                    matched_mods.insert(module->name);
        }

        for (auto id : matched_mods)
            log("Matched module: %s\n", id.c_str());

        for (auto module : design->selected_modules()) {
            log("Processing module %s\n", module->name.c_str());
            for (auto cell : module->selected_cells()) {
                if (!matched_mods.count(cell->type))
                    continue;

                Module *tpl = design->module(cell->type);
                IdString orig_name = tpl->get_string_attribute(ID::hdlname);
                log("Cell %s: %s -> %s\n", cell->name.c_str(), cell->type.c_str(), orig_name.c_str());
                cell->type = orig_name;
                cell->parameters = tpl->parameter_default_values;
            }
        }

        log_pop();
    }

} EmuRestoreParamCells;

PRIVATE_NAMESPACE_END
