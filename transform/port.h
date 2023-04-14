#ifndef _EMU_TRANSFORM_PORT_H_
#define _EMU_TRANSFORM_PORT_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"
#include "utils.h"

namespace REMU {

struct CommonPort
{
    enum Type {
        PT_INPUT,
        PT_OUTPUT,
        PT_OUTPUT_AND,
        PT_OUTPUT_OR,
    };

    struct Info {
        Yosys::IdString id;
        bool autoconn;
        Type type;

        static std::vector<Info*> list;

        Info(Yosys::IdString id, bool autoconn, Type type)
            : id(id), autoconn(autoconn), type(type)
        {
            list.push_back(this);
        }
    };

    static const Info PORT_HOST_CLK;
    static const Info PORT_HOST_RST;
    static const Info PORT_MDL_CLK;
    static const Info PORT_MDL_CLK_FF;
    static const Info PORT_MDL_CLK_RAM;
    static const Info PORT_MDL_RST;
    static const Info PORT_RUN_MODE;
    static const Info PORT_SCAN_MODE;
    static const Info PORT_IDLE;
    static const Info PORT_FF_SE;
    static const Info PORT_FF_DI;
    static const Info PORT_FF_DO;
    static const Info PORT_RAM_SR;
    static const Info PORT_RAM_SE;
    static const Info PORT_RAM_SD;
    static const Info PORT_RAM_DI;
    static const Info PORT_RAM_DO;
    static const Info PORT_RAM_LI;
    static const Info PORT_RAM_LO;

    static const Yosys::dict<std::string, const Info *> name_dict;

    static const Info& info_by_name(const std::string &name)
    {
        return *name_dict.at(name);
    }

    static void create_ports(Yosys::Module *module);
    static Yosys::Wire* get(Yosys::Module *module, const Info &id);
    static void put(Yosys::Module *module, const Info &id, Yosys::SigSpec sig);
};

inline void promote_port(Yosys::Cell *sub, Yosys::IdString port, Yosys::IdString sub_port)
{
    USING_YOSYS_NAMESPACE
    Module *module = sub->module;
    Wire *sub_wire = module->design->module(sub->type)->wire(sub_port);
    if (!sub_wire)
        return;
    Wire *wire = module->addWire(port, sub_wire);
    sub->setPort(sub_port, wire);
}

template<typename T>
void promote_ports
(
    Hierarchy &hier,
    Yosys::Module *module,
    std::vector<T> &ports,
    const Yosys::dict<Yosys::IdString, std::vector<T>> &submodule_ports
)
{
    USING_YOSYS_NAMESPACE
    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *sub = module->cell(edge.name.second);

        for (auto &subinfo : submodule_ports.at(child.name)) {
            auto info = subinfo;
            std::string sub_name = id2str(sub->name);
            IdString port = module->uniquify("\\" + sub_name + "_" + subinfo.port_name);
            IdString sub_port = "\\" + subinfo.port_name;
            info.name.insert(info.name.begin(), sub_name);
            info.port_name = id2str(port);
            promote_port(sub, port, sub_port);
            ports.push_back(info);
        }
    }
}

};

#endif // #ifndef _EMU_TRANSFORM_PORT_H_
