#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "utils.h"

#include <sstream>

using namespace Emu;

USING_YOSYS_NAMESPACE

std::vector<CommonPort::Info*> CommonPort::Info::list;

const CommonPort::Info CommonPort::PORT_HOST_CLK    ("\\EMU_HOST_CLK",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_HOST_RST    ("\\EMU_HOST_RST",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK     ("\\EMU_MDL_CLK",       true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK_FF  ("\\EMU_MDL_CLK_FF",    true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK_RAM ("\\EMU_MDL_CLK_RAM",   true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_RST     ("\\EMU_MDL_RST",       true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_RUN_MODE    ("\\EMU_RUN_MODE",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_SCAN_MODE   ("\\EMU_SCAN_MODE",     true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_IDLE        ("\\EMU_IDLE",          true,   PT_OUTPUT_AND);
const CommonPort::Info CommonPort::PORT_FF_SE       ("\\EMU_FF_SE",         false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_FF_DI       ("\\EMU_FF_DI",         false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_FF_DO       ("\\EMU_FF_DO",         false,  PT_OUTPUT);
const CommonPort::Info CommonPort::PORT_RAM_SR      ("\\EMU_RAM_SR",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_SE      ("\\EMU_RAM_SE",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_SD      ("\\EMU_RAM_SD",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_DI      ("\\EMU_RAM_DI",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_DO      ("\\EMU_RAM_DO",        false,  PT_OUTPUT);
const CommonPort::Info CommonPort::PORT_RAM_LI      ("\\EMU_RAM_LI",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_LO      ("\\EMU_RAM_LO",        false,  PT_OUTPUT);

const Yosys::dict<std::string, const CommonPort::Info*> CommonPort::name_dict = {
    {"mdl_clk",     &CommonPort::PORT_MDL_CLK},
    {"mdl_rst",     &CommonPort::PORT_MDL_RST},
    {"run_mode",    &CommonPort::PORT_RUN_MODE},
    {"scan_mode",   &CommonPort::PORT_SCAN_MODE},
    {"idle",        &CommonPort::PORT_IDLE},
    // other ports are not allowed in verilog source code
};

void CommonPort::create_ports(Module *module)
{
    for (auto info : Info::list) {
        Wire *wire = module->addWire(info->id);
        switch (info->type) {
            case PT_INPUT:
                wire->port_input = true;
                break;
            case PT_OUTPUT:
            case PT_OUTPUT_AND:
            case PT_OUTPUT_OR:
                wire->port_output = true;
                if (info->type == PT_OUTPUT_AND)
                    module->connect(wire, State::S1);
                else if (info->type == PT_OUTPUT_OR)
                    module->connect(wire, State::S0);
                break;
            default:
                log_error("unknown port direction for %s\n", log_id(info->id));
        }
    }
    module->fixup_ports();
}

Wire* CommonPort::get(Module *module, const Info &info)
{
    return module->wire(info.id);
}

void CommonPort::put(Module *module, const Info &info, SigSpec sig)
{
    Wire *wire = module->wire(info.id);
    if (info.type == PT_OUTPUT) {
        module->connect(wire, sig);
    }
    else if (info.type == PT_OUTPUT_AND || info.type == PT_OUTPUT_OR) {
        module->rename(wire, NEW_ID);
        Wire *new_wire = module->addWire(info.id, wire);
        wire->port_output = false;
        if (info.type == PT_OUTPUT_AND)
            module->addAnd(NEW_ID, wire, sig, new_wire);
        else
            module->addOr(NEW_ID, wire, sig, new_wire);
        // no need to call fixup_ports()
    }
    else {
        log_error("unknown port direction for %s\n", log_id(info.id));
    }
}

PRIVATE_NAMESPACE_BEGIN

Wire* export_sub_port(Cell *sub, IdString sub_port, IdString port)
{
    Module *module = sub->module;
    Wire *sub_wire = module->design->module(sub->type)->wire(sub_port);
    Wire *wire = module->addWire(port, sub_wire);
    sub->setPort(sub_port, wire);
    return wire;
}

PRIVATE_NAMESPACE_END

void PortTransform::promote_user_sigs(Module *module)
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
        info.orig_name = id2str(wire->name);
        info.port_name = id2str(wire->name);
        wire->port_input = true;
        wire->port_output = false;
        info.ff_clk = "\\" + info.port_name + "_FF";
        info.ram_clk = "\\" + info.port_name + "_RAM";
        Wire *ff_clk = module->addWire(info.ff_clk);
        Wire *ram_clk = module->addWire(info.ram_clk);
        ff_clk->port_input = true;
        ram_clk->port_input = true;
        wire->set_string_attribute("\\associated_ff_clk", info.ff_clk.str());
        wire->set_string_attribute("\\associated_ram_clk", info.ram_clk.str());
        clockinfo.push_back(info);
    }

    for (Wire *wire : resets) {
        log_assert(wire->width == 1);
        ResetInfo info;
        info.orig_name = id2str(wire->name);
        info.port_name = id2str(wire->name);
        wire->port_input = true;
        wire->port_output = false;
        resetinfo.push_back(info);
    }

    for (Wire *wire : trigs) {
        log_assert(wire->width == 1);
        TrigInfo info;
        info.orig_name = id2str(wire->name);
        info.port_name = id2str(wire->name);
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
            newinfo.path.insert(newinfo.path.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_PORT_" + join_string(newinfo.path, '_') + "_" + info.orig_name;
            newinfo.ff_clk = "\\" + newinfo.port_name + "_FF";
            newinfo.ram_clk = "\\" + newinfo.port_name + "_RAM";
            Wire *newport = export_sub_port(inst, "\\" + info.port_name, "\\" + newinfo.port_name);
            export_sub_port(inst, info.ff_clk, newinfo.ff_clk);
            export_sub_port(inst, info.ram_clk, newinfo.ram_clk);
            newport->set_string_attribute("\\associated_ff_clk", newinfo.ff_clk.str());
            newport->set_string_attribute("\\associated_ram_clk", newinfo.ram_clk.str());
            clockinfo.push_back(newinfo);
        }

        for (auto &info : all_reset_ports.at(child.name)) {
            ResetInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_PORT_" + join_string(newinfo.path, '_') + "_" + info.orig_name;
            export_sub_port(inst, "\\" + info.port_name, "\\" + newinfo.port_name);
            resetinfo.push_back(newinfo);
        }

        for (auto &info : all_trig_ports.at(child.name)) {
            TrigInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_PORT_" + join_string(newinfo.path, '_') + "_" + info.orig_name;
            export_sub_port(inst, "\\" + info.port_name, "\\" + newinfo.port_name);
            triginfo.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_clock_ports[module->name] = clockinfo;
    all_reset_ports[module->name] = resetinfo;
    all_trig_ports[module->name] = triginfo;
}

void PortTransform::promote_common_ports(Module *module)
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
        if (info.type == CommonPort::PT_INPUT) {
            module->connect(wire, CommonPort::get(module, info));
        }
        else {
            CommonPort::put(module, info, wire);
        }
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        Cell *inst = module->cell(edge.name.second);

        for (auto info : CommonPort::Info::list) {
            if (info->autoconn) {
                Wire *wire = module->addWire(NEW_ID);
                inst->setPort(info->id, wire);
                if (info->type == CommonPort::PT_INPUT) {
                    module->connect(wire, CommonPort::get(module, *info));
                }
                else {
                    CommonPort::put(module, *info, wire);
                }
            }
        }
    }

    module->fixup_ports();
}

void PortTransform::promote_pipe_ports(Module *module)
{
    std::vector<PipeInfo> streams;

    // process this module

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string name = wire->get_string_attribute(Attr::PipeName);
        if (name.empty())
            continue;

        PipeInfo info;
        info.orig_name = name;
        info.port_name = name;

        std::string dir = wire->get_string_attribute(Attr::PipeDirection);
        if (dir.empty())
            log_error("missing direction for pipe port %s\n", name.c_str());

        if (dir != "in" && dir != "out")
            log_error("unrecognized dir for pipe port %s\n", name.c_str());

        info.output = dir == "out";

        std::string type = wire->get_string_attribute(Attr::PipeType);
        if (type.empty())
            log_error("missing type for pipe port %s\n", name.c_str());

        if (type != "pio" && type != "dma")
            log_error("unrecognized type for pipe port %s\n", name.c_str());

        info.type = type;

        {
            Wire *wire_valid = module->wire("\\" + name + "_valid");
            log_assert(wire_valid && wire_valid->width == 1);
            log_assert(wire_valid->port_output == info.output);
            log_assert(wire_valid->port_input == !info.output);
            info.port_valid = wire_valid->name;
        }

        {
            Wire *wire_data = module->wire("\\" + name + "_data");
            log_assert(wire_data);
            log_assert(wire_data->port_output == info.output);
            log_assert(wire_data->port_input == !info.output);
            info.port_data = wire_data->name;
            info.width = GetSize(wire_data);
        }

        {
            Wire *wire_ready = module->wire("\\" + name + "_ready");
            log_assert(wire_ready && wire_ready->width == 1);
            log_assert(wire_ready->port_output == !info.output);
            log_assert(wire_ready->port_input == info.output);
            info.port_ready = wire_ready->name;
        }

        if (!info.output) {
            Wire *wire_empty = module->wire("\\" + name + "_empty");
            log_assert(wire_empty->port_output == info.output);
            log_assert(wire_empty->port_input == !info.output);
            log_assert(wire_empty && wire_empty->width == 1);
            info.port_empty = wire_empty->name;
        }

        streams.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_pipe_ports.at(child.name)) {
            PipeInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_PORT_" + join_string(newinfo.path, '_') + "_" + info.orig_name;
            newinfo.port_valid = "\\" + newinfo.port_name + "_valid";
            newinfo.port_data = "\\" + newinfo.port_name + "_data";
            export_sub_port(inst, info.port_valid, newinfo.port_valid);
            export_sub_port(inst, info.port_data, newinfo.port_data);
            streams.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_pipe_ports[module->name] = streams;
}

void PortTransform::promote_channel_ports(Module *module)
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

        // Process channel payload

        SigSpec new_payload, old_payload;

        std::string payload = wire->get_string_attribute(Attr::ChannelPayload);
        if (!payload.empty()) {
            std::vector<std::string> port_list = split_string(payload, ' ');
            for (auto &port : port_list) {
                size_t prefix_len = port.size();

                // wildcard match
                if (port.back() == '*')
                    prefix_len--;

                std::string prefix = port.substr(0, prefix_len);
                for (auto &id : module->ports) {
                    if (id[0] != '\\' || id.substr(1, prefix_len) != prefix)
                        continue;

                    Wire *op = module->wire(id);
                    module->rename(op, NEW_ID);
                    Wire *np = module->addWire(id, op);
                    op->port_input = false;
                    op->port_output = false;
                    new_payload.append(np);
                    old_payload.append(op);
                }
            }
        }

        int payload_width = GetSize(new_payload);
        Wire *payload_inner = module->addWire("\\" + name + "_payload_inner", payload_width);
        Wire *payload_outer = module->addWire("\\" + name + "_payload_outer", payload_width);
        payload_inner->port_input = info.dir == ChannelInfo::IN;
        payload_inner->port_output = !payload_inner->port_input;
        payload_outer->port_input = info.dir == ChannelInfo::OUT;
        payload_outer->port_output = !payload_outer->port_input;

        if (info.dir == ChannelInfo::IN) {
            module->connect(payload_outer, new_payload);
            module->connect(old_payload, payload_inner);
        }
        else {
            module->connect(payload_inner, old_payload);
            module->connect(new_payload, payload_outer);
        }

        info.port_payload_inner = payload_inner->name;
        info.port_payload_outer = payload_outer->name;

        channels.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_channel_ports.at(child.name)) {
            ChannelInfo newinfo = info;
            newinfo.path.insert(newinfo.path.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_PORT_" + join_string(newinfo.path, '_') + "_" + info.orig_name;
            newinfo.port_valid = "\\" + newinfo.port_name + "_valid";
            newinfo.port_ready = "\\" + newinfo.port_name + "_ready";
            newinfo.port_payload_inner = "\\" + newinfo.port_name + "_payload_inner";
            newinfo.port_payload_outer = "\\" + newinfo.port_name + "_payload_outer";
            export_sub_port(inst, info.port_valid, newinfo.port_valid);
            export_sub_port(inst, info.port_ready, newinfo.port_ready);
            export_sub_port(inst, info.port_payload_inner, newinfo.port_payload_inner);
            export_sub_port(inst, info.port_payload_outer, newinfo.port_payload_outer);
            channels.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_channel_ports[module->name] = channels;
}

void PortTransform::run()
{
    if (hier.design->scratchpad_get_bool("emu.port.promoted")) {
        log("Design is already processed.\n");
        return;
    }

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        promote_user_sigs(module);
        promote_common_ports(module);
        promote_pipe_ports(module);
        promote_channel_ports(module);
    }

    IdString top = hier.dag.rootNode().name;
    database.user_clocks = all_clock_ports.at(top);
    database.user_resets = all_reset_ports.at(top);
    database.user_trigs = all_trig_ports.at(top);
    database.pipes = all_pipe_ports.at(top);
    database.channels = all_channel_ports.at(top);

    Module *top_module = hier.design->module(top);
    Wire *host_rst = CommonPort::get(top_module, CommonPort::PORT_HOST_RST);
    Wire *mdl_rst = CommonPort::get(top_module, CommonPort::PORT_MDL_RST);
    make_internal(mdl_rst);
    top_module->connect(mdl_rst, host_rst);
    top_module->fixup_ports();

    hier.design->scratchpad_set_bool("emu.port.promoted", true);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestPort : public Pass {
    EmuTestPort() : Pass("emu_test_port", "test port functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_PORT pass.\n");

        EmulationDatabase database;
        PortTransform worker(design, database);

        worker.run();
        database.write_yaml("output.yml");
    }
} EmuTestPort;

PRIVATE_NAMESPACE_END
