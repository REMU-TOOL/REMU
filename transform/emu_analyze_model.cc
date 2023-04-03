#include "kernel/yosys.h"

#include "attr.h"
#include "hier.h"
#include "database.h"
#include "utils.h"

using namespace REMU;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct ModelAnalyzer
{
    Hierarchy hier;
    EmulationDatabase &database;

    void run();

    ModelAnalyzer(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

void ModelAnalyzer::run()
{
    dict<IdString, std::vector<SysInfo::ModelInfo>> all_model_infos;

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));

        std::vector<SysInfo::ModelInfo> model_infos;

        for (auto cell : module->cells()) {
            Module *tpl = hier.design->module(cell->type);
            if (!tpl || !tpl->has_attribute(Attr::ModelType))
                continue;

            std::string type = tpl->get_string_attribute(Attr::ModelType);
            if (type.empty())
                log_error("Module %s: model type must not be empty\n", log_id(tpl));

            SysInfo::ModelInfo info;
            info.name = {id2str(cell->name)};
            info.type = type;

            for (auto param : tpl->parameter_default_values) {
                auto &name = param.first;
                if (name.begins_with("\\C_S_")) {
                    info.str_params[id2str(name)] = param.second.decode_string();
                }
                else if (name.begins_with("\\C_I_")) {
                    info.int_params[id2str(name)] = param.second.as_int();
                }
            }

            model_infos.push_back(std::move(info));

            auto &node = hier.dag.findNode(module->name);
            for (auto &edge : node.outEdges()) {
                auto &child = edge.toNode();
                for (auto &info : all_model_infos.at(child.name)) {
                    SysInfo::ModelInfo newinfo = info;
                    newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
                }
            }
        }

        all_model_infos[module->name] = model_infos;
    }

    IdString top = hier.dag.rootNode().name;
    for (auto info : all_model_infos.at(top)) {
        info.name.insert(info.name.begin(), "EMU_TOP");
        database.model.push_back(info);
    }
}

struct EmuAnalyzeModel : public Pass
{
    EmuAnalyzeModel() : Pass("emu_analyze_model", "(REMU internal)") {}

    void execute(vector<string> args, Design* design) override
    {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_ANALYZE_MODEL pass.\n");
        log_push();

        ModelAnalyzer worker(design, EmulationDatabase::get_instance(design));
        worker.run();

        log_pop();
    }
} EmuAnalyzeModel;

PRIVATE_NAMESPACE_END
