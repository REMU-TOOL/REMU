#ifndef _EMU_PORT_H_
#define _EMU_PORT_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct CommonPort
{
    enum ID {
        NAME_HOST_CLK = 0,
        NAME_HOST_RST,
        NAME_MDL_CLK,
        NAME_MDL_RST,
        NAME_RUN_MODE,
        NAME_SCAN_MODE,
        NAME_IDLE,
        NAME_FF_SE,
        NAME_FF_DI,
        NAME_FF_DO,
        NAME_RAM_SR,
        NAME_RAM_SE,
        NAME_RAM_SD,
        NAME_RAM_DI,
        NAME_RAM_DO,
    };

    enum Type {
        PORT_INPUT,
        PORT_OUTPUT,
        PORT_OUTPUT_ANDREDUCE,
        PORT_OUTPUT_ORREDUCE,
    };

    struct Info {
        ID id;
        Yosys::IdString id_str;
        bool autoconn;
        Type type;
    };

    static const std::vector<Info> info_list;
    static const Yosys::dict<std::string, ID> name_list;

    static const Info& info_by_id(ID id)
    {
        return info_list.at(id);
    }

    static const Info& info_by_name(const std::string &name)
    {
        return info_by_id(name_list.at(name));
    }

    static void create_ports(Yosys::Module *module);
    static Yosys::Wire* get(Yosys::Module *module, ID id);
    static void put(Yosys::Module *module, ID id, Yosys::SigSpec sig);
};

struct PortTransformer
{
    Hierarchy &hier;
    EmulationDatabase &database;

    Yosys::dict<Yosys::IdString, std::vector<ClockInfo>> all_clock_ports;
    Yosys::dict<Yosys::IdString, std::vector<ResetInfo>> all_reset_ports;
    Yosys::dict<Yosys::IdString, std::vector<TrigInfo>> all_trig_ports;
    Yosys::dict<Yosys::IdString, std::vector<FifoPortInfo>> all_fifo_ports;
    Yosys::dict<Yosys::IdString, std::vector<ChannelInfo>> all_channel_ports;

    void promote_user_sigs(Yosys::Module *module);
    void promote_common_ports(Yosys::Module *module);
    void promote_fifo_ports(Yosys::Module *module);
    void promote_channel_ports(Yosys::Module *module);

    void promote();

    PortTransformer(Hierarchy &hier, EmulationDatabase &database)
        : hier(hier), database(database) {}
};

};

#endif // #ifndef _EMU_PORT_H_
