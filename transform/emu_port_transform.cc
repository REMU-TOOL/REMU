#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "utils.h"
#include "TraceBackend/Top.hpp"
#include <cstddef>
#include <fstream>
#include <sstream>
#include <string>

using namespace REMU;

USING_YOSYS_NAMESPACE

std::vector<CommonPort::Info*> CommonPort::Info::list;

const CommonPort::Info CommonPort::PORT_HOST_CLK      ("\\EMU_HOST_CLK",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_HOST_RST      ("\\EMU_HOST_RST",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK       ("\\EMU_MDL_CLK",       true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK_FF    ("\\EMU_MDL_CLK_FF",    true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_CLK_RAM   ("\\EMU_MDL_CLK_RAM",   true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_MDL_RST       ("\\EMU_MDL_RST",       true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_PAUSE_PENDING ("\\EMU_PAUSE_PENDING", true,   PT_OUTPUT_OR);
const CommonPort::Info CommonPort::PORT_RUN_MODE      ("\\EMU_RUN_MODE",      true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_SCAN_MODE     ("\\EMU_SCAN_MODE",     true,   PT_INPUT);
const CommonPort::Info CommonPort::PORT_IDLE          ("\\EMU_IDLE",          true,   PT_OUTPUT_AND);
const CommonPort::Info CommonPort::PORT_FF_SE         ("\\EMU_FF_SE",         false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_FF_DI         ("\\EMU_FF_DI",         false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_FF_DO         ("\\EMU_FF_DO",         false,  PT_OUTPUT);
const CommonPort::Info CommonPort::PORT_RAM_SR        ("\\EMU_RAM_SR",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_SE        ("\\EMU_RAM_SE",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_SD        ("\\EMU_RAM_SD",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_DI        ("\\EMU_RAM_DI",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_DO        ("\\EMU_RAM_DO",        false,  PT_OUTPUT);
const CommonPort::Info CommonPort::PORT_RAM_LI        ("\\EMU_RAM_LI",        false,  PT_INPUT);
const CommonPort::Info CommonPort::PORT_RAM_LO        ("\\EMU_RAM_LO",        false,  PT_OUTPUT);

const Yosys::dict<std::string, const CommonPort::Info*> CommonPort::name_dict = {
    {"mdl_clk",      &CommonPort::PORT_MDL_CLK},
    {"mdl_rst",      &CommonPort::PORT_MDL_RST},
    {"pause_pending",&CommonPort::PORT_PAUSE_PENDING},
    {"run_mode",     &CommonPort::PORT_RUN_MODE},
    {"scan_mode",    &CommonPort::PORT_SCAN_MODE},
    {"idle",         &CommonPort::PORT_IDLE},
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

struct PortTransform
{
    Hierarchy hier;
    EmulationDatabase &database;
    std::string trace_backend;

    Yosys::dict<Yosys::IdString, std::vector<ClockPort>> all_clock_ports;
    Yosys::dict<Yosys::IdString, std::vector<SignalPort>> all_signal_ports;
    Yosys::dict<Yosys::IdString, std::vector<TriggerPort>> all_trigger_ports;
    Yosys::dict<Yosys::IdString, std::vector<AXIPort>> all_axi_ports;
    Yosys::dict<Yosys::IdString, std::vector<TracePort>> all_trace_ports;

    void process_common_ports(Yosys::Module *module);
    void process_clocks(Yosys::Module *module);
    void process_signals(Yosys::Module *module);
    void process_triggers(Yosys::Module *module);
    void process_axi_ports(Yosys::Module *module);
    void process_trace_ports(Yosys::Module *module);

    void run(std::string trace_backend);

    PortTransform(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

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

        log("Identified clock %s\n", log_id(wire));

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
    std::vector<SignalPort> info_list;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Ignore clocks
        if (wire->get_bool_attribute(Attr::REMUClock))
            continue;

        if (!wire->get_bool_attribute(Attr::REMUSignal))
            continue;

        log("Identified signal %s\n", log_id(wire));

        if (wire->port_input && wire->port_output)
            log_error("signal %s cannot be an inout port\n",
                log_id(wire));

        wire->set_bool_attribute(Attr::REMUSignal, false);

        std::string init;
        if (wire->port_input && wire->has_attribute(Attr::REMUSignalInit)) {
            Const initval = wire->attributes.at(Attr::REMUSignalInit);
            if (wire->is_signed)
                initval.exts(wire->width);
            else
                initval.extu(wire->width);
            init = initval.as_string();
        }

        SignalPort info;
        info.port_name = id2str(wire->name);
        info.name = {info.port_name};
        info.width = wire->width;
        info.output = wire->port_output;
        info.init = init;
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

        log("Identified trigger %s\n", log_id(wire));

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

void PortTransform::process_axi_ports(Module *module)
{
    std::vector<AXIPort> info_list;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string type = wire->get_string_attribute(Attr::AxiType);

        if (type != "axi4" && type !="axi4-dma")
            continue;

        std::string name = wire->get_string_attribute(Attr::AxiName);

        if (!wire->has_attribute(Attr::AxiSize) && type == "axi4")
            log_error("AXI interface %s does not have size specified\n",
                name.c_str());

        AXIPort info;
        info.name = {name};
        info.port_name = name;
        info.axi = axi4_from_prefix(module, name);
        if(type == "axi4")
            info.size = const_as_u64(wire->attributes.at(Attr::AxiSize));
        else
            info.size = 0;

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
            if(newinfo.size != 0)
                newinfo.port_name = "EMU_AXI_" + join_string(newinfo.name, '_');
            else
                newinfo.port_name = "EMU_DMA_AXI_" + join_string(newinfo.name, '_');
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

void PortTransform::process_trace_ports(Module *module)
{
    std::vector<TracePort> info_list;
    pool<std::string> port_names;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get channel name
    
        std::string name = wire->get_string_attribute(Attr::TracePortName);
        if (name.empty())
            continue;

        log("Identified trace port %s\n", name.c_str());

        // Check if channel already exists

        if (port_names.count(name) > 0)
            log_error("%s.%s: trace port %s is already defined\n", 
                log_id(module), log_id(wire), name.c_str());

        port_names.insert(name);

        TracePort info;
        info.name = {name};
        info.port_name = name;
        info.type = wire->get_string_attribute(Attr::TracePortType);

        // Process valid/ready/data ports

        {
            std::string wire_name = wire->get_string_attribute(Attr::TracePortValid);
            if (wire_name.empty())
                log_error("%s.%s: valid port of trace port %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            Wire *wire_valid = module->wire("\\" + wire_name);
            if (wire_valid == nullptr)
                log_error("%s.%s: valid port %s of trace port %s does not exist\n", 
                    log_id(module), log_id(wire), wire_name.c_str(), name.c_str());

            info.port_valid = wire_valid->name;
        }

        {
            std::string wire_name = wire->get_string_attribute(Attr::TracePortReady);
            if (wire_name.empty())
                log_error("%s.%s: ready port of trace port %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            Wire *wire_ready = module->wire("\\" + wire_name);
            if (wire_ready == nullptr)
                log_error("%s.%s: ready port %s of trace port %s does not exist\n", 
                    log_id(module), log_id(wire), wire_name.c_str(), name.c_str());

            info.port_ready = wire_ready->name;
        }

        {
            std::string wire_name = wire->get_string_attribute(Attr::TracePortData);
            if (wire_name.empty())
                log_error("%s.%s: data port of trace port %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            Wire *wire_data = module->wire("\\" + wire_name);
            if (wire_data == nullptr)
                log_error("%s.%s: data port %s of trace port %s does not exist\n", 
                    log_id(module), log_id(wire), wire_name.c_str(), name.c_str());

            info.port_data = wire_data->name;
            info.port_width = wire_data->width;
        }

        info_list.push_back(info);
    }

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_trace_ports.at(child.name)) {
            auto newinfo = info;
            newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_TRACE_" + join_string(newinfo.name, '_');
            newinfo.port_valid = "\\" + newinfo.port_name + "_valid";
            newinfo.port_ready = "\\" + newinfo.port_name + "_ready";
            newinfo.port_data = "\\" + newinfo.port_name + "_data";
            promote_port(inst, newinfo.port_valid, info.port_valid);
            promote_port(inst, newinfo.port_ready, info.port_ready);
            promote_port(inst, newinfo.port_data, info.port_data);
            info_list.push_back(newinfo);
        }
    }

    module->fixup_ports();
    all_trace_ports[module->name] = info_list;
}

template<typename T>
void copy_top_info(std::vector<T> &to, const std::vector<T> &from)
{
    to.clear();
    for (auto x : from) {
        x.name.insert(x.name.begin(), "EMU_TOP");
        to.push_back(x);
    }
}

void PortTransform::run(std::string trace_backend)
{
    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        process_common_ports(module);
        process_clocks(module);
        process_signals(module);
        process_triggers(module);
        process_axi_ports(module);
        process_trace_ports(module);
    }
    PortTransform::trace_backend = trace_backend;
    IdString top = hier.dag.rootNode().name;
    copy_top_info(database.clock_ports, all_clock_ports.at(top));
    copy_top_info(database.signal_ports, all_signal_ports.at(top));
    copy_top_info(database.trigger_ports, all_trigger_ports.at(top));
    copy_top_info(database.axi_ports, all_axi_ports.at(top));
    copy_top_info(database.trace_ports, all_trace_ports.at(top));

    Module *top_module = hier.design->module(top);
    Wire *host_rst  = CommonPort::get(top_module, CommonPort::PORT_HOST_RST);
    Wire *mdl_rst   = CommonPort::get(top_module, CommonPort::PORT_MDL_RST);

    make_internal(mdl_rst);
    top_module->connect(mdl_rst, host_rst);

    top_module->fixup_ports();
    std::vector<size_t> traceport_width;
    for (auto &info : database.trace_ports) {
        if(info.type != "uart_tx"){
            traceport_width.push_back(info.port_width);
            std::cout<< info.port_width << std::endl;
        }
    }
    if (!traceport_width.empty()) {
      std::ofstream out_file(trace_backend);
      if (!out_file.is_open()) {
        log_error("Cannot open file: %s\n", trace_backend.c_str());
      }
      auto backend = TraceBackend(traceport_width);
      out_file << backend.emitVerilog() << std::endl;
    }
}

struct EmuPortTransform : public Pass
{
    EmuPortTransform() : Pass("emu_port_transform", "(REMU internal)") {}

    std::string trace_backend;
    void execute(vector<string> args, Design* design) override
    {
        size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-tracebackend") {
				trace_backend = args[++argidx];
				continue;
			}
			break;
		}
		extra_args(args, argidx, design);
        log_header(design, "Executing EMU_PORT_TRANSFORM pass.\n");
        log_push();

        PortTransform worker(design, EmulationDatabase::get_instance(design));
        worker.run(trace_backend);

        log_pop();
    }
} EmuPortTransform;

PRIVATE_NAMESPACE_END
