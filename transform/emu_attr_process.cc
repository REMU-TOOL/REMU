#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuPreserveTopPass : public Pass {
    EmuPreserveTopPass() : Pass("emu_preserve_top", "add keep attribute to cells & wires in top module") { }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PRESERVE_TOP pass.\n");

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            break;
        }
        extra_args(args, argidx, design);

        Module *top = design->top_module();
        if (!top)
            log_error("No top module found");
        
        log("Processing module %s...\n", log_id(top));

        for (auto cell : top->selected_cells())
            cell->set_bool_attribute(ID::keep);

        for (auto wire : top->selected_wires())
            wire->set_bool_attribute(ID::keep);
    }

} EmuPreserveTopPass;

struct EmuRemoveKeepPass : public Pass {
    EmuRemoveKeepPass() : Pass("emu_remove_keep", "remove all keep attributes") { }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_REMOVE_KEEP pass.\n");

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            break;
        }
        extra_args(args, argidx, design);

        for (auto mod : design->modules()) {
            log("Processing module %s...\n", log_id(mod));
            mod->set_bool_attribute(ID::keep, false);

            for (auto cell : mod->selected_cells())
                cell->set_bool_attribute(ID::keep, false);

            for (auto wire : mod->selected_wires())
                wire->set_bool_attribute(ID::keep, false);
        }
    }
} EmuRemoveKeepPass;

struct EmuPropAttrPass : public Pass {
    EmuPropAttrPass() : Pass("emu_prop_attr", "propagate specified attributes to submodule") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_prop_attr [options]\n");
        log("\n");
        log("This command propagates the specified attribute from parent cell to cells &\n");
        log("wires in submodule.\n");
        log("\n");
        log("    -a <attr>\n");
        log("        specify the attribute to propagate. (may be used multiple times)\n");
        log("\n");
    }

    void append_attrs(dict<IdString, Const> &to, const dict<IdString, Const> &from) {
        for (auto &it : from)
            to[it.first] = it.second;
    }

    IdString prop_attrs_to_module(Module *module, const dict<IdString, Const> &attrs_to_prop) {
        log("Mapping attributes to module %s ...\n", log_id(module));

        Design *design = module->design;

        std::string new_mdl_name = module->name.str() + "$PROPATTR";
        for (auto &it : attrs_to_prop) {
            new_mdl_name += it.first.str() + "=" + it.second.as_string();
            log("Attribute %s = %d\n", it.first.c_str(), it.second.as_int());
        }

        IdString new_mdl_id = new_mdl_name;
        if (design->has(new_mdl_id))
            return new_mdl_id;

        log("New module: %s\n", new_mdl_id.c_str());
        Module *new_module = module->clone();
        new_module->name = new_mdl_id;
        design->add(new_module);

        for (auto wire : new_module->wires())
            append_attrs(wire->attributes, attrs_to_prop);

        for (auto cell : new_module->cells()) {
            append_attrs(cell->attributes, attrs_to_prop);

            if (!design->has(cell->type))
                continue;

            Module *target = design->module(cell->type);
            cell->type = prop_attrs_to_module(target, attrs_to_prop);
        }

        return new_mdl_id;
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PROP_ATTR pass.\n");

        pool<IdString> attrs;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-a" && argidx+1 < args.size()) {
                attrs.insert(RTLIL::escape_id(args[++argidx]));
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        auto modules = design->selected_modules();
        for (auto module : modules) {
            log("Processing module %s...\n", log_id(module));

            for (auto cell : module->selected_cells()) {
                if (!module->design->has(cell->type))
                    continue;

                dict<IdString, Const> attrs_to_prop;
                for (auto &attr : cell->attributes) {
                    if (attrs.count(attr.first))
                        attrs_to_prop[attr.first] = attr.second;
                }
                attrs_to_prop.sort();

                if (attrs_to_prop.size() == 0)
                    continue;

                Module *target = module->design->module(cell->type);
                cell->type = prop_attrs_to_module(target, attrs_to_prop);
            }
        }
    }
} EmuPropAttrPass;

PRIVATE_NAMESPACE_END
