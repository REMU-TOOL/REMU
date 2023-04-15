#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "clock.h"
#include "hier.h"
#include "database.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace REMU;

PRIVATE_NAMESPACE_BEGIN

struct ChannelPort
{
    std::vector<std::string> name;
    std::string port_name;
    enum {IN, OUT} dir;
    Wire *valid;
    Wire *ready;
    Wire *clock;
    SigSpec new_payload;
    SigSpec old_payload;
    Yosys::IdString port_finishing; // exported to top
    std::vector<std::string> deps; // relative to path
};

struct FAMETransform
{
    Hierarchy hier;
    EmulationDatabase &database;

    Yosys::dict<Yosys::IdString, std::vector<ChannelPort>> all_channel_ports;

    void process_channel_ports(Yosys::Module *module);
    void run();

    FAMETransform(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

Cell* ClockGate(Module *module, IdString name, SigSpec clk, SigSpec en, SigSpec oclk)
{
    Cell *cell = module->addCell(name, "\\ClockGate");
    cell->setPort("\\CLK", clk);
    cell->setPort("\\EN", en);
    cell->setPort("\\OCLK", oclk);
    return cell;
}

void rewrite_channel(Module *module, ChannelPort &channel)
{
    Wire *mdl_clk       = CommonPort::get(module, CommonPort::PORT_MDL_CLK);
    Wire *mdl_rst       = CommonPort::get(module, CommonPort::PORT_MDL_RST);
    Wire *run_mode      = CommonPort::get(module, CommonPort::PORT_RUN_MODE);

    Wire *tick = module->wire(clk_to_tick(channel.clock));

    make_internal(channel.valid);
    make_internal(channel.ready);

    SigSpec fire = module->And(NEW_ID, channel.valid, channel.ready);
    SigSpec done = module->addWire(NEW_ID);

    // always @(posedge clk)
    //   if (rst || tick)
    //     done <= 1'b0;
    //   else if (fire)
    //     done <= 1'b1;
    module->addSdffe(NEW_ID,
        mdl_clk,
        fire,
        module->Or(NEW_ID, mdl_rst, tick),
        State::S1,
        done,
        State::S0
    );

    // Note: direction is in model module's view
    if (channel.dir == ChannelPort::IN) {
        // assign valid = !done && run_mode;
        module->connect(channel.valid, module->And(NEW_ID, module->Not(NEW_ID, done), run_mode));
        // connect payload signals
        module->connect(channel.old_payload, channel.new_payload);
    }
    else {
        // assign ready = !done && run_mode;
        module->connect(channel.ready, module->And(NEW_ID, module->Not(NEW_ID, done), run_mode));
        // insert buffers for payload signals
        // always @(posedge clk)
        //   if (fire)
        //     payload_r <= old_payload;
        // assign new_payload = done ? payload_r : old_payload;
        Wire *payload_r = module->addWire(NEW_ID, GetSize(channel.new_payload));
        module->addDffe(NEW_ID,
            mdl_clk,
            fire,
            channel.old_payload,
            payload_r);
        module->addMux(NEW_ID, channel.old_payload, payload_r, done, channel.new_payload);
    }

    channel.port_finishing = "\\" + channel.port_name + "_finishing";
    Wire *finishing = module->addWire(channel.port_finishing);
    finishing->port_output = true;
    module->connect(finishing, module->Or(NEW_ID, fire, done));
}

void FAMETransform::process_channel_ports(Module *module)
{
    std::vector<ChannelPort> info_list;
    pool<std::string> channel_names;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get channel name
    
        std::string name = wire->get_string_attribute(Attr::ChannelName);
        if (name.empty())
            continue;

        log("Identified channel port %s\n", name.c_str());

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
        {
            std::string valid = wire->get_string_attribute(Attr::ChannelValid);
            if (valid.empty())
                log_error("%s.%s: valid port of channel %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            info.valid = module->wire("\\" + valid);
            if (info.valid == nullptr)
                log_error("%s.%s: valid port %s of channel %s does not exist\n", 
                    log_id(module), log_id(wire), valid.c_str(), name.c_str());
        }

        {
            std::string ready = wire->get_string_attribute(Attr::ChannelReady);
            if (ready.empty())
                log_error("%s.%s: ready port of channel %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            info.ready = module->wire("\\" + ready);
            if (info.ready == nullptr)
                log_error("%s.%s: ready port %s of channel %s does not exist\n", 
                    log_id(module), log_id(wire), ready.c_str(), name.c_str());
        }

        // Process channel clock
        {
            std::string clock = wire->get_string_attribute(Attr::ChannelClock);
            if (clock.empty())
                log_error("%s.%s: clock port of channel %s is required\n", 
                    log_id(module), log_id(wire), name.c_str());

            info.clock = module->wire("\\" + clock);
            if (info.clock == nullptr)
                log_error("%s.%s: clock port %s of channel %s does not exist\n", 
                    log_id(module), log_id(wire), clock.c_str(), name.c_str());
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
                for (auto &id : module->ports) {
                    if (id[0] != '\\' || id.substr(1, prefix_len) != prefix)
                        continue;

                    Wire *op = module->wire(id);
                    module->rename(op, NEW_ID);
                    Wire *np = module->addWire(id, op);
                    op->port_input = false;
                    op->port_output = false;
                    info.new_payload.append(np);
                    info.old_payload.append(op);
                }
            }
        }

        // Rewrite channel signals
        rewrite_channel(module, info);

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
            newinfo.port_finishing = "\\" + newinfo.port_name + "_finishing";
            promote_port(inst, newinfo.port_finishing, info.port_finishing);
            info_list.push_back(newinfo);
        }
    }

    module->fixup_ports();
    all_channel_ports[module->name] = info_list;
}

void FAMETransform::run()
{
    Module *top = hier.design->top_module();

    // TODO: handle combinationally connected channels
    // TODO: support multiple clocks

    Wire *tick = top->addWire("\\EMU_TICK");
    tick->port_output = true;

    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *mdl_clk       = CommonPort::get(top, CommonPort::PORT_MDL_CLK);
    Wire *mdl_clk_ff    = CommonPort::get(top, CommonPort::PORT_MDL_CLK_FF);
    Wire *mdl_clk_ram   = CommonPort::get(top, CommonPort::PORT_MDL_CLK_RAM);
    Wire *mdl_rst       = CommonPort::get(top, CommonPort::PORT_MDL_RST);
    Wire *run_mode      = CommonPort::get(top, CommonPort::PORT_RUN_MODE);
    Wire *scan_mode     = CommonPort::get(top, CommonPort::PORT_SCAN_MODE);
    Wire *ff_se         = CommonPort::get(top, CommonPort::PORT_FF_SE);
    Wire *ram_se        = CommonPort::get(top, CommonPort::PORT_RAM_SE);

    SigSpec not_scan_mode = top->Not(NEW_ID, scan_mode);
    SigSpec run_and_tick = top->And(NEW_ID, run_mode, tick);

    make_internal(mdl_clk);
    make_internal(mdl_clk_ff);
    make_internal(mdl_clk_ram);

    // Generate model clocks

    ClockGate(top, NEW_ID, host_clk, not_scan_mode, mdl_clk);
    ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, not_scan_mode, ff_se), mdl_clk_ff);
    ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, not_scan_mode, ram_se), mdl_clk_ram);

    // Generate user clocks

    for (auto &info : database.clock_ports) {
        Wire *clk = top->wire("\\" + info.port_name);
        Wire *clk_ff = top->wire(to_ff_clk(clk));
        Wire *clk_ram = top->wire(to_ram_clk(clk));
        Wire *clk_tick = top->wire(clk_to_tick(clk));

        make_internal(clk);
        make_internal(clk_ff);
        make_internal(clk_ram);
        make_internal(clk_tick);

        top->connect(clk, State::S0);
        ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, run_and_tick, ff_se), clk_ff);
        ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, run_and_tick, ram_se), clk_ram);
        top->connect(clk_tick, tick); // TODO: generate individual tick signals for each clock

        info.index = 0; // TODO
    }

    // Process channel signals

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        process_channel_ports(module);
    }

    SigSpec finishing = State::S1;
    for (auto &info : all_channel_ports.at(top->name)) {
        Wire *channel_finishing = top->wire(info.port_finishing);
        finishing.append(channel_finishing);
    }

    top->connect(tick, top->ReduceAnd(NEW_ID, finishing));

    // Add FFs to output user signals to save their values in the previous cycle

    for (auto &info : database.signal_ports) {
        if (info.output) {
            // For output signals, delay 1 target cycle to capture
            // the value before the clock edge when a trigger is active
            Wire *sig_wire = top->wire("\\" + info.port_name);
            make_internal(sig_wire);
            info.port_name += "_REG";
            Wire *reg_wire = top->addWire("\\" + info.port_name, info.width);
            reg_wire->port_output = true;
            reg_wire->set_bool_attribute(Attr::AnonymousFF);
            // TODO: analyze clock source to determine which tick signal should be used (for multiple clock support)
            top->addSdffe(NEW_ID,
                mdl_clk, run_and_tick, mdl_rst, sig_wire, reg_wire, Const(0, info.width));
        }
    }

    top->fixup_ports();
}

struct EmuFameTransform : public Pass
{
    EmuFameTransform() : Pass("emu_fame_transform", "(REMU internal)") {}

    void execute(vector<string> args, Design* design) override
    {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_FAME_TRANSFORM pass.\n");
        log_push();

        FAMETransform worker(design, EmulationDatabase::get_instance(design));
        worker.run();

        log_pop();
    }
} EmuFameTransform;

PRIVATE_NAMESPACE_END
