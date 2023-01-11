#include "kernel/yosys.h"

#include "attr.h"
#include "model.h"
#include "utils.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

void ModelAnalyzer::run()
{
    dict<IdString, std::vector<ModelInfo>> all_model_infos;

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));

        std::vector<ModelInfo> model_infos;

        for (auto cell : module->cells()) {
            Module *tpl = hier.design->module(cell->type);
            if (!tpl || !tpl->has_attribute(Attr::ModelType))
                continue;

            std::string type = tpl->get_string_attribute(Attr::ModelType);
            if (type.empty())
                log_error("Module %s: model type must not be empty\n", log_id(tpl));

            ModelInfo info;
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
                    ModelInfo newinfo = info;
                    newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
                }
            }
        }

        all_model_infos[module->name] = model_infos;
    }

    IdString top = hier.dag.rootNode().name;
    database.models = all_model_infos.at(top);
}
