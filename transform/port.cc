#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "utils.h"

#include <sstream>

using namespace REMU;

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

void promote_port(Cell *sub, IdString port, IdString sub_port)
{
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
    Module *module,
    std::vector<T> &ports,
    const dict<IdString, std::vector<T>> &submodule_ports
)
{
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

PRIVATE_NAMESPACE_END

void PortTransform::process_common_ports(Module *module)
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

void PortTransform::process_clocks(Module *module)
{
    std::vector<Wire*> wire_list;
    std::vector<ClockPort> info_list;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        if (!wire->get_bool_attribute(Attr::REMUClock))
            continue;

        if (wire->port_output)
            log_error("clock %s must be an input port\n",
                log_id(wire));

        if (wire->width != 1)
            log_error("the width of clock signal %s must be 1\n",
                log_id(wire));

        wire->set_bool_attribute(Attr::REMUClock, false);
        wire_list.push_back(wire);
    }

    for (auto wire : wire_list) {
        ClockPort info;
        info.port_name = id2str(wire->name);
        info.name = {info.port_name};
        info_list.push_back(info);
    }

    promote_ports(hier, module, info_list, all_clock_ports);
    module->fixup_ports();
    all_clock_ports[module->name] = info_list;
}

void PortTransform::process_signals(Module *module)
{
    std::vector<Wire*> wire_list;
    std::vector<SignalPort> info_list;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Ignore clocks
        if (wire->get_bool_attribute(Attr::REMUClock))
            continue;

        if (!wire->get_bool_attribute(Attr::REMUSignal))
            continue;

        if (wire->port_input && wire->port_output)
            log_error("signal %s cannot be an inout port\n",
                log_id(wire));

        wire->set_bool_attribute(Attr::REMUSignal, false);
        wire_list.push_back(wire);
    }

    for (auto wire : wire_list) {
        SignalPort info;
        info.port_name = id2str(wire->name);
        info.name = {info.port_name};
        info.width = wire->width;
        info.output = wire->port_output;
        info_list.push_back(info);
    }

    promote_ports(hier, module, info_list, all_signal_ports);
    module->fixup_ports();
    all_signal_ports[module->name] = info_list;
}

void PortTransform::process_triggers(Module *module)
{
    std::vector<Wire*> wire_list;
    std::vector<TriggerPort> info_list;

    for (auto wire : module->wires()) {
        if (!wire->get_bool_attribute(Attr::REMUTrig))
            continue;

        if (wire->width != 1)
            log_error("the width of trigger signal %s must be 1\n",
                log_id(wire));

        wire->set_bool_attribute(Attr::REMUTrig, false);
        wire_list.push_back(wire);
    }

    for (auto wire : wire_list) {
        // Add an additional output wire in case the original wire is an input port
        Wire *trigger_wire = module->addWire(wire->name.str() + "_TRIGGER");
        trigger_wire->port_output = true;
        module->connect(trigger_wire, wire);

        TriggerPort info;
        info.name = {id2str(wire->name)};
        info.port_name = id2str(trigger_wire->name);
        info_list.push_back(info);
    }

    promote_ports(hier, module, info_list, all_trigger_ports);
    module->fixup_ports();
    all_trigger_ports[module->name] = info_list;
}

PRIVATE_NAMESPACE_BEGIN

void sig_from_wire(AXI::Sig &sig, Wire *wire)
{
    if (!wire || wire->port_input == wire->port_output) {
        sig.width = 0;
        return;
    }
    sig.name = id2str(wire->name);
    sig.width = wire->width;
    sig.output = wire->port_output;
}

#define FROM_PREFIX(ch, sig) \
    sig_from_wire(axi.ch.sig, module->wire("\\" + prefix + "_" #ch #sig))

AXI::AXI4 axi4_from_prefix(Module *module, const std::string &prefix)
{
    AXI::AXI4 axi;
    FROM_PREFIX(aw, valid);
    FROM_PREFIX(aw, ready);
    FROM_PREFIX(aw, addr);
    FROM_PREFIX(aw, prot);
    FROM_PREFIX(aw, id);
    FROM_PREFIX(aw, len);
    FROM_PREFIX(aw, size);
    FROM_PREFIX(aw, burst);
    FROM_PREFIX(aw, lock);
    FROM_PREFIX(aw, cache);
    FROM_PREFIX(aw, qos);
    FROM_PREFIX(aw, region);
    FROM_PREFIX(w, valid);
    FROM_PREFIX(w, ready);
    FROM_PREFIX(w, data);
    FROM_PREFIX(w, strb);
    FROM_PREFIX(w, last);
    FROM_PREFIX(b, valid);
    FROM_PREFIX(b, ready);
    FROM_PREFIX(b, resp);
    FROM_PREFIX(b, id);
    FROM_PREFIX(ar, valid);
    FROM_PREFIX(ar, ready);
    FROM_PREFIX(ar, addr);
    FROM_PREFIX(ar, prot);
    FROM_PREFIX(ar, id);
    FROM_PREFIX(ar, len);
    FROM_PREFIX(ar, size);
    FROM_PREFIX(ar, burst);
    FROM_PREFIX(ar, lock);
    FROM_PREFIX(ar, cache);
    FROM_PREFIX(ar, qos);
    FROM_PREFIX(ar, region);
    FROM_PREFIX(r, valid);
    FROM_PREFIX(r, ready);
    FROM_PREFIX(r, data);
    FROM_PREFIX(r, resp);
    FROM_PREFIX(r, id);
    FROM_PREFIX(r, last);
    return axi;
}

PRIVATE_NAMESPACE_END

void PortTransform::process_axi_ports(Module *module)
{
    std::vector<AXIPort> info_list;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string type = wire->get_string_attribute(Attr::AxiType);

        if (type != "axi4")
            continue;

        std::string name = wire->get_string_attribute(Attr::AxiName);

        if (!wire->has_attribute(Attr::AxiSize))
            log_error("AXI interface %s does not have size specified\n",
                name.c_str());

        AXIPort info;
        info.name = {name};
        info.port_name = name;
        info.axi = axi4_from_prefix(module, name);
        info.size = const_as_u64(wire->attributes.at(Attr::AxiSize));

        info.axi.check();

        log("Identified %s %s interface %s with size = 0x%lx\n",
            info.axi.isFull() ? "AXI4" : "AXI4-lite",
            info.axi.isMaster() ? "master" : "slave",
            name.c_str(),
            info.size);

        info_list.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_axi_ports.at(child.name)) {
            AXIPort newinfo = info;
            newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_AXI_" + join_string(newinfo.name, '_');
            newinfo.axi.setPrefix(newinfo.port_name);

            auto sub_sigs = info.axi.signals();
            auto new_sigs = newinfo.axi.signals();
            for (
                auto sub_it = sub_sigs.begin(), sub_ie = sub_sigs.end(),
                new_it = new_sigs.begin(), new_ie = new_sigs.end();
                sub_it != sub_ie && new_it != new_ie;
                ++sub_it, ++new_it
            ) {
                if (!sub_it->present())
                    continue;

                Wire *wire = module->addWire("\\" + new_it->name, new_it->width);
                wire->port_input = !new_it->output;
                wire->port_output = new_it->output;
                inst->setPort("\\" + sub_it->name, wire);
            }

            info_list.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_axi_ports[module->name] = info_list;
}

void PortTransform::process_channel_ports(Module *module)
{
    std::vector<ChannelPort> info_list;
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

        ChannelPort info;
        info.name = {name};
        info.port_name = name;

        // Process channel direction

        std::string direction = wire->get_string_attribute(Attr::ChannelDirection);
        if (direction.empty())
            log_error("%s.%s: direction of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());

        if (direction == "in" || direction == "out") {
            info.dir = direction == "in" ? ChannelPort::IN : ChannelPort::OUT;
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

        wire_valid->port_input = info.dir == ChannelPort::IN;
        wire_valid->port_output = !wire_valid->port_input;
        wire_ready->port_input = !wire_valid->port_input;
        wire_ready->port_output = !wire_ready->port_input;

        info_list.push_back(info);
    }

    // export submodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_channel_ports.at(child.name)) {
            auto newinfo = info;
            newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_CHANNEL_" + join_string(newinfo.name, '_');
            newinfo.port_valid = "\\" + newinfo.port_name + "_valid";
            newinfo.port_ready = "\\" + newinfo.port_name + "_ready";
            promote_port(inst, newinfo.port_valid, info.port_valid);
            promote_port(inst, newinfo.port_ready, info.port_ready);
            info_list.push_back(newinfo);
        }
    }

    module->fixup_ports();
    all_channel_ports[module->name] = info_list;
}

void PortTransform::run()
{
    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        process_common_ports(module);
        process_clocks(module);
        process_signals(module);
        process_triggers(module);
        process_axi_ports(module);
        process_channel_ports(module);
    }

    IdString top = hier.dag.rootNode().name;
    database.clock_ports = all_clock_ports.at(top);
    database.signal_ports = all_signal_ports.at(top);
    database.trigger_ports = all_trigger_ports.at(top);
    database.axi_ports = all_axi_ports.at(top);
    database.channel_ports = all_channel_ports.at(top);

    Module *top_module = hier.design->module(top);
    Wire *host_rst  = CommonPort::get(top_module, CommonPort::PORT_HOST_RST);
    Wire *mdl_rst   = CommonPort::get(top_module, CommonPort::PORT_MDL_RST);

    make_internal(mdl_rst);
    top_module->connect(mdl_rst, host_rst);

    top_module->fixup_ports();
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
        database.write_sysinfo("output.json");
    }
} EmuTestPort;

PRIVATE_NAMESPACE_END
