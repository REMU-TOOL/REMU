#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "utils.h"

#include <sstream>

using namespace Emu;

USING_YOSYS_NAMESPACE

const std::vector<CommonPort::Info> CommonPort::info_list = {
    {NAME_HOST_CLK,     "\\EMU_HOST_CLK",   true,   PORT_INPUT},
    {NAME_HOST_RST,     "\\EMU_HOST_RST",   true,   PORT_INPUT},
    {NAME_MDL_CLK,      "\\EMU_MDL_CLK",    true,   PORT_INPUT},
    {NAME_MDL_RST,      "\\EMU_MDL_RST",    true,   PORT_INPUT},
    {NAME_RUN_MODE,     "\\EMU_RUN_MODE",   true,   PORT_INPUT},
    {NAME_SCAN_MODE,    "\\EMU_SCAN_MODE",  true,   PORT_INPUT},
    {NAME_IDLE,         "\\EMU_IDLE",       true,   PORT_OUTPUT_ANDREDUCE},
    {NAME_FF_SE,        "\\EMU_FF_SE",      false,  PORT_INPUT},
    {NAME_FF_DI,        "\\EMU_FF_DI",      false,  PORT_INPUT},
    {NAME_FF_DO,        "\\EMU_FF_DO",      false,  PORT_OUTPUT},
    {NAME_RAM_SR,       "\\EMU_RAM_SR",     false,  PORT_INPUT},
    {NAME_RAM_SE,       "\\EMU_RAM_SE",     false,  PORT_INPUT},
    {NAME_RAM_SD,       "\\EMU_RAM_SD",     false,  PORT_INPUT},
    {NAME_RAM_DI,       "\\EMU_RAM_DI",     false,  PORT_INPUT},
    {NAME_RAM_DO,       "\\EMU_RAM_DO",     false,  PORT_OUTPUT},
    {NAME_RAM_LI,       "\\EMU_RAM_LI",     false,  PORT_INPUT},
    {NAME_RAM_LO,       "\\EMU_RAM_LO",     false,  PORT_OUTPUT},
};

const Yosys::dict<std::string, CommonPort::ID> CommonPort::name_list = {
    {"mdl_clk",     NAME_MDL_CLK},
    {"mdl_rst",     NAME_MDL_RST},
    {"run_mode",    NAME_RUN_MODE},
    {"scan_mode",   NAME_SCAN_MODE},
    {"idle",        NAME_IDLE},
    // other ports are not allowed in verilog source code
};

void CommonPort::create_ports(Module *module)
{
    for (auto &info : info_list) {
        Wire *wire = module->addWire(info.id_str);
        switch (info.type) {
            case PORT_INPUT:
                wire->port_input = true;
                break;
            case PORT_OUTPUT:
            case PORT_OUTPUT_ANDREDUCE:
            case PORT_OUTPUT_ORREDUCE:
                wire->port_output = true;
                if (info.type == PORT_OUTPUT_ANDREDUCE)
                    module->connect(wire, State::S1);
                else if (info.type == PORT_OUTPUT_ORREDUCE)
                    module->connect(wire, State::S0);
                break;
            default:
                log_error("unknown port direction for %s\n", log_id(info.id_str));
        }
    }
    module->fixup_ports();
}

Wire* CommonPort::get(Module *module, ID id)
{
    return module->wire(info_by_id(id).id_str);
}

void CommonPort::put(Module *module, ID id, SigSpec sig)
{
    auto &info = info_by_id(id);
    Wire *wire = module->wire(info_by_id(id).id_str);
    if (info.type == PORT_OUTPUT) {
        module->connect(wire, sig);
    }
    else if (info.type == PORT_OUTPUT_ANDREDUCE || info.type == PORT_OUTPUT_ORREDUCE) {
        module->rename(wire, NEW_ID);
        Wire *new_wire = module->addWire(info.id_str, wire);
        wire->port_output = false;
        if (info.type == PORT_OUTPUT_ANDREDUCE)
            module->addAnd(NEW_ID, wire, sig, new_wire);
        else
            module->addOr(NEW_ID, wire, sig, new_wire);
        // no need to call fixup_ports()
    }
    else {
        log_error("unknown port direction for %s\n", log_id(info.id_str));
    }
}

inline std::string path_prefix(const std::vector<Yosys::IdString> &path)
{
    std::ostringstream ss;
    for (auto &p : path)
        ss << pretty_name(p) << "_";
    return ss.str();
}

void PortTransformer::promote_user_sigs(Module *module)
{
    std::vector<Wire *> clocks, resets, trigs;

    std::vector<ClockInfo> clockinfo;
    std::vector<ResetInfo> resetinfo;
    std::vector<TrigInfo> triginfo;

    // scan ports

    for (auto port : module->ports) {
        Wire *wire = module->wire(port);
        if (wire->get_bool_attribute(Attr::UserClock))
            clocks.push_back(wire);
        else if (wire->get_bool_attribute(Attr::UserReset))
            resets.push_back(wire);
        else if (wire->get_bool_attribute(Attr::UserTrig))
            trigs.push_back(wire);
    }

    // process this module

    for (Wire *wire : clocks) {
        log_assert(wire->width == 1);
        ClockInfo info;
        info.orig_name = wire->name;
        info.port_name = wire->name;
        wire->port_input = true;
        wire->port_output = false;
        clockinfo.push_back(info);
    }

    for (Wire *wire : resets) {
        log_assert(wire->width == 1);
        ResetInfo info;
        info.orig_name = wire->name;
        info.port_name = wire->name;
        wire->port_input = true;
        wire->port_output = false;
        resetinfo.push_back(info);
    }

    for (Wire *wire : trigs) {
        log_assert(wire->width == 1);
        TrigInfo info;
        info.orig_name = wire->name;
        info.port_name = wire->name;
        wire->port_input = false;
        wire->port_output = true;
        triginfo.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_clock_ports.at(child.name)) {
            ClockInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), edge.name.second);
            newinfo.port_name = "\\EMU_PORT_" + path_prefix(newinfo.path) + pretty_name(info.port_name);
            Wire *newport = module->addWire(newinfo.port_name);
            newport->port_input = true;
            inst->setPort(info.port_name, newport);
            clockinfo.push_back(newinfo);
        }

        for (auto &info : all_reset_ports.at(child.name)) {
            ResetInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), edge.name.second);
            newinfo.port_name = "\\EMU_PORT_" + path_prefix(newinfo.path) + pretty_name(info.port_name);
            Wire *newport = module->addWire(newinfo.port_name);
            newport->port_input = true;
            inst->setPort(info.port_name, newport);
            resetinfo.push_back(newinfo);
        }

        for (auto &info : all_trig_ports.at(child.name)) {
            TrigInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), edge.name.second);
            newinfo.port_name = "\\EMU_PORT_" + path_prefix(newinfo.path) + pretty_name(info.port_name);
            Wire *newport = module->addWire(newinfo.port_name);
            newport->port_output = true;
            inst->setPort(info.port_name, newport);
            triginfo.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_clock_ports[module->name] = clockinfo;
    all_reset_ports[module->name] = resetinfo;
    all_trig_ports[module->name] = triginfo;
}

void PortTransformer::promote_common_ports(Module *module)
{
    CommonPort::create_ports(module);

    // process this module

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get common port attribute
        std::string name = wire->get_string_attribute(Attr::CommonPort);
        if (name.empty())
            continue;

        log_assert(wire->width == 1);
        wire->port_input = false;
        wire->port_output = false;

        auto &info = CommonPort::info_by_name(name);
        if (info.type == CommonPort::PORT_INPUT) {
            module->connect(wire, CommonPort::get(module, info.id));
        }
        else {
            CommonPort::put(module, info.id, wire);
        }
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : CommonPort::info_list) {
            if (info.autoconn) {
                Wire *wire = module->addWire(NEW_ID);
                inst->setPort(info.id_str, wire);
                if (info.type == CommonPort::PORT_INPUT) {
                    module->connect(wire, CommonPort::get(module, info.id));
                }
                else {
                    CommonPort::put(module, info.id, wire);
                }
            }
        }
    }

    module->fixup_ports();
}

void PortTransformer::promote_fifo_ports(Module *module)
{
    std::vector<FifoPortInfo> fifoportinfo;

    // process this module

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string name = wire->get_string_attribute(Attr::FifoPortName);
        if (name.empty())
            continue;

        FifoPortInfo info;
        info.orig_name = name;
        info.port_name = name;

        std::string type = wire->get_string_attribute(Attr::FifoPortType);
        if (type.empty())
            log_error("missing type in fifo port %s\n", name.c_str());

        if (type != "sink" && type != "source")
            log_error("wrong type in fifo port %s\n", name.c_str());

        info.type = type == "sink" ? FifoPortInfo::SINK : FifoPortInfo::SOURCE;

        std::string enable_attr = wire->get_string_attribute(Attr::FifoPortEnable);
        if (enable_attr.empty())
            log_error("missing enable port in fifo port %s\n", name.c_str());

        std::string data_attr = wire->get_string_attribute(Attr::FifoPortData);
        if (data_attr.empty())
            log_error("missing data port in fifo port %s\n", name.c_str());

        std::string flag_attr = wire->get_string_attribute(Attr::FifoPortFlag);
        if (flag_attr.empty())
            log_error("missing flag port in fifo port %s\n", name.c_str());

        Wire *wire_enable = module->wire("\\" + enable_attr);
        Wire *wire_data = module->wire("\\" + data_attr);
        Wire *wire_flag = module->wire("\\" + flag_attr);

        log_assert(wire_enable && wire_enable->width == 1);
        log_assert(wire_data);
        log_assert(wire_flag && wire_flag->width == 1);

        info.port_enable = wire_enable->name;
        info.port_data = wire_data->name;
        info.port_flag = wire_flag->name;

        wire_enable->port_input = true;
        wire_enable->port_output = false;
        wire_data->port_input = info.type == FifoPortInfo::SOURCE;
        wire_data->port_output = !wire_data->port_input;
        wire_flag->port_input = false;
        wire_flag->port_output = true;

        info.width = GetSize(wire_data);

        fifoportinfo.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_fifo_ports.at(child.name)) {
            FifoPortInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), edge.name.second);
            newinfo.port_name = "EMU_PORT_" + path_prefix(newinfo.path) + info.port_name;
            newinfo.port_enable = "\\" + newinfo.port_name + "_enable";
            newinfo.port_data = "\\" + newinfo.port_name + "_data";
            newinfo.port_flag = "\\" + newinfo.port_name + "_flag";

            Wire *wire_enable = module->addWire(newinfo.port_enable);
            wire_enable->port_input = true;
            wire_enable->port_output = false;
            inst->setPort(info.port_enable, wire_enable);
            Wire *wire_data = module->addWire(newinfo.port_data, newinfo.width);
            wire_data->port_input = newinfo.type == 0;
            wire_data->port_output = !wire_data->port_input;
            inst->setPort(info.port_data, wire_data);
            Wire *wire_flag = module->addWire(newinfo.port_flag);
            wire_flag->port_input = false;
            wire_flag->port_output = true;
            inst->setPort(info.port_flag, wire_flag);

            fifoportinfo.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_fifo_ports[module->name] = fifoportinfo;
}

void PortTransformer::promote_channel_ports(Module *module)
{
    std::vector<ChannelInfo> channels;
    pool<std::string> channel_names;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get channel name
    
        std::string name = wire->get_string_attribute(Attr::ChannelName);
        if (name.empty())
            continue;

        // Check if channel already exists

        if (channel_names.count(name) > 0)
            log_error("%s.%s: channel %s is already defined\n", 
                log_id(module), log_id(wire), name.c_str());

        channel_names.insert(name);

        ChannelInfo info;
        info.orig_name = name;
        info.port_name = name;

        // Process channel direction

        std::string direction = wire->get_string_attribute(Attr::ChannelDirection);
        if (direction.empty())
            log_error("%s.%s: direction of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());

        if (direction == "in" || direction == "out") {
            info.dir = direction == "in" ? ChannelInfo::IN : ChannelInfo::OUT;
        }
        else {
            log_error("%s.%s: invalid channel direction \"%s\"\n", log_id(module), log_id(wire), direction.c_str());
        }

        // Process channel dependencies

        std::string dependencies = wire->get_string_attribute(Attr::ChannelDependsOn);
        if (!dependencies.empty()) {
            std::vector<std::string> dep_list = split_string(dependencies, ' ');
            for (auto &dep : dep_list)
                if (!dep.empty())
                    info.deps.push_back(dep);
        }

        // Process channel payload

        std::string payload = wire->get_string_attribute(Attr::ChannelPayload);
        if (!payload.empty()) {
            std::vector<std::string> port_list = split_string(payload, ' ');
            for (auto &port : port_list) {
                size_t prefix_len = port.size();

                // wildcard match
                if (port.back() == '*')
                    prefix_len--;

                std::string prefix = port.substr(0, prefix_len);
                for (auto &id : module->ports)
                    if (id[0] == '\\' && id.substr(1, prefix_len) == prefix)
                        info.payloads.push_back(id);
            }
        }

        // Process channel valid/ready port

        std::string valid = wire->get_string_attribute(Attr::ChannelValid);
        if (valid.empty())
            log_error("%s.%s: valid port of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());

        Wire *wire_valid = module->wire("\\" + valid);
        if (wire_valid == nullptr)
            log_error("%s.%s: valid port %s of channel %s does not exist\n", 
                log_id(module), log_id(wire), valid.c_str(), name.c_str());

        info.port_valid = wire_valid->name;

        std::string ready = wire->get_string_attribute(Attr::ChannelReady);
        if (ready.empty())
            log_error("%s.%s: ready port of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());

        Wire *wire_ready = module->wire("\\" + ready);
        if (wire_ready == nullptr)
            log_error("%s.%s: ready port %s of channel %s does not exist\n", 
                log_id(module), log_id(wire), ready.c_str(), name.c_str());

        info.port_ready = wire_ready->name;

        wire_valid->port_input = info.dir == ChannelInfo::IN;
        wire_valid->port_output = !wire_valid->port_input;
        wire_ready->port_input = !wire_valid->port_input;
        wire_ready->port_output = !wire_ready->port_input;

        channels.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_channel_ports.at(child.name)) {
            ChannelInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), edge.name.second);
            newinfo.port_name = "EMU_PORT_" + path_prefix(newinfo.path) + info.port_name;
            newinfo.port_valid = "\\" + newinfo.port_name + "_valid";
            newinfo.port_ready = "\\" + newinfo.port_name + "_ready";

            Wire *wire_valid = module->addWire(newinfo.port_valid);
            wire_valid->port_input = info.dir == ChannelInfo::IN;
            wire_valid->port_output = !wire_valid->port_input;
            inst->setPort(info.port_valid, wire_valid);
            Wire *wire_ready = module->addWire(newinfo.port_ready);
            wire_ready->port_input = !wire_valid->port_input;
            wire_ready->port_output = !wire_ready->port_input;
            inst->setPort(info.port_ready, wire_ready);

            channels.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_channel_ports[module->name] = channels;
}

void PortTransformer::promote()
{
    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        promote_user_sigs(module);
        promote_common_ports(module);
        promote_fifo_ports(module);
        promote_channel_ports(module);
    }
    IdString top = hier.dag.rootNode().name;
    database.user_clocks = all_clock_ports.at(top);
    database.user_resets = all_reset_ports.at(top);
    database.user_trigs = all_trig_ports.at(top);
    database.fifo_ports = all_fifo_ports.at(top);
    database.channels = all_channel_ports.at(top);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestPort : public Pass {
    EmuTestPort() : Pass("emu_test_port", "test port functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_PORT pass.\n");

        EmulationDatabase database;
        PortTransformer worker(design, database);

        worker.promote();
        database.write_yaml("output.yml");
    }
} EmuTestPort;

PRIVATE_NAMESPACE_END
