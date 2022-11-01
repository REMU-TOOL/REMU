#ifndef _EMU_PORT_H_
#define _EMU_PORT_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

enum CommonPortType {
    PORT_INPUT,
    PORT_OUTPUT_ANDREDUCE,
    PORT_OUTPUT_ORREDUCE,
};

struct CommonPortInfo {
    Yosys::IdString id;
    CommonPortType type;
};

extern const Yosys::dict<std::string, CommonPortInfo> common_ports;

struct PortTransformer
{
    Yosys::Design *design;
    Hierarchy &hier;
    EmulationDatabase &database;

    void promote_user_sigs(Yosys::Module *module);
    void promote_common_ports(Yosys::Module *module);
    void promote_fifo_ports(Yosys::Module *module);
    void promote_channel_ports(Yosys::Module *module);

    void promote();
};

};

#endif // #ifndef _EMU_PORT_H_
