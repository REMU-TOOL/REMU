#ifndef _EMU_TRANSFORM_PORT_H_
#define _EMU_TRANSFORM_PORT_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

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

};

#endif // #ifndef _EMU_TRANSFORM_PORT_H_
