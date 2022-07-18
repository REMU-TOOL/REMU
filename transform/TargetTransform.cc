#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

#include <queue>

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

std::vector<std::string> split_string(std::string s, char delim) {
    std::vector<std::string> result;
    size_t start = 0, end = 0;
    while ((end = s.find(delim, start)) != std::string::npos) {
        result.push_back(s.substr(start, end));
        start = end + 1;
    }
    result.push_back(s.substr(start));
    return result;
}

struct RTLModelWorker {

    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    DesignInfo &designinfo;

    enum ModelChannelDirection { CHANNEL_INPUT, CHANNEL_OUTPUT };

    struct ModelChannel {
        Module *module;
        std::string name;
        ModelChannelDirection direction;
        pool<std::string> dependencies;
        Wire *valid;
        Wire *ready;
        pool<Wire *> payloads;
    };

    using ChannelId = std::pair<Module *, std::string>;

    dict<ChannelId, ModelChannel> channels;
    dict<ChannelId, pool<ChannelId>> model_channel_deps;
    dict<ChannelId, pool<ChannelId>> rtl_channel_deps;

    void analyze();
    void analyze_module(Module *module);
    void emit();

    void run();

    RTLModelWorker(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter), designinfo(rewriter.design()) {}

};

void RTLModelWorker::analyze() {
    struct Context {
        Module *module;
        bool is_model_context;
    };
    std::queue<Context> work_queue;

    // Add top module to work queue
    work_queue.push({rewriter.design().top(), false});

    while (!work_queue.empty()) {
        // Get the first module from work queue
        auto ctxt = work_queue.front();
        work_queue.pop();

        // Check if the module is a model
        if (ctxt.module->get_bool_attribute(Attr::ModelImp)) {
            // Add model to transform list if the model is instantiated in non-model context
            if (!ctxt.is_model_context)
                analyze_module(ctxt.module);

            ctxt.is_model_context = true;
        }

        // Add children modules to work queue
        for (Module *sub : rewriter.design().children_of(ctxt.module))
            work_queue.push({sub, ctxt.is_model_context});
    }

    // Check channel direction & port direction consistency

    for (auto &it : channels) {
        auto &channel = it.second;

        bool channel_input = channel.direction == CHANNEL_INPUT;
        bool channel_output = channel.direction == CHANNEL_OUTPUT;

        if (channel.valid->port_input != channel_input || channel.valid->port_output != channel_output)
            log_error("%s: valid port %s has inconsistent direction with channel %s\n",
                log_id(channel.module), log_id(channel.valid), channel.name.c_str());

        if (channel.ready->port_input != !channel_input || channel.ready->port_output != !channel_output)
            log_error("%s: ready port %s has inconsistent direction with channel %s\n",
                log_id(channel.module), log_id(channel.ready), channel.name.c_str());

        for (auto payload : channel.payloads) {
            if (payload->port_input != channel_input || payload->port_output != channel_output)
                log_error("%s: payload port %s has inconsistent direction with channel %s\n",
                    log_id(channel.module), log_id(payload), channel.name.c_str());
        }
    }

    // Analyze model channel dependencies

    for (auto &it : channels) {
        auto &channel = it.second;
        model_channel_deps[it.first].clear();

        for (auto &dep : channel.dependencies) {
            if (channels.count({channel.module, dep}) == 0)
                log_error("%s: depencency channel %s by channel %s does not exist\n",
                    log_id(channel.module), dep.c_str(), channel.name.c_str());

            model_channel_deps[it.first].insert({channel.module, dep});
        }
    }

    // Analyze RTL channel dependencies

    pool<ChannelId> input_channels, output_channels;

    for (auto &it : channels) {
        auto &channel = it.second;
        rtl_channel_deps[it.first].clear();

        // Channel direction in RTL's view is opposite to model's view
        if (channel.direction == CHANNEL_INPUT)
            output_channels.insert(it.first);
        else
            input_channels.insert(it.first);
    }

    pool<SigBit> all_ic_bits;
    dict<SigBit, ChannelId> ic_bit2id_map;

    for (auto &ic : input_channels) {
        for (Wire *wire : channels[ic].payloads) {
            for (SigBit &b : SigSpec(wire)) {
                all_ic_bits.insert(b);
                ic_bit2id_map[b] = ic;
            }
        }
    }

    for (auto &oc : output_channels) {
        pool<SigBit> oc_bits;
        for (Wire *wire : channels[oc].payloads)
            for (SigBit &b : SigSpec(wire))
                oc_bits.insert(b);

        for (SigBit &b : rewriter.design().find_dependencies(oc_bits, all_ic_bits))
            rtl_channel_deps[oc].insert(ic_bit2id_map[b]);
    }

    // Check for circular dependencies

    TopoSort<ChannelId> topo;

    for (auto &it : channels) {
        topo.node(it.first);
        for (auto &dep : model_channel_deps[it.first])
            topo.edge(dep, it.first);
        for (auto &dep : rtl_channel_deps[it.first])
            topo.edge(dep, it.first);
    }

    log("Channel dependencies:\n");
    for (auto &it : topo.database)
        for (auto &dep : it.second)
            log("  %s.%s(%s) -> %s.%s(%s)\n",
                rewriter.design().hier_name_of(dep.first).c_str(),
                dep.second.c_str(),
                channels.at(dep).direction == CHANNEL_INPUT ? "in" : "out",
                rewriter.design().hier_name_of(it.first.first).c_str(),
                it.first.second.c_str(),
                channels.at(it.first).direction == CHANNEL_INPUT ? "in" : "out"
            );
    log("------------------------------\n");

    if (!topo.sort()) {
        log("Found dependency loops in model channels:\n");
        for (auto &loop : topo.loops) {
            log("Loop:\n");
            for (auto &id : loop)
                log("  %s.%s\n", rewriter.design().hier_name_of(id.first).c_str(), id.second.c_str());
            log("------------------------------\n");
        }
        log_error("Model channel dependency loop found\n");
    }
}

void RTLModelWorker::analyze_module(Module *module) {
    // Traverse all ports

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get channel name
    
        std::string name = wire->get_string_attribute(Attr::ChannelName);
        if (name.empty())
            continue;

        // Check if channel already exists

        if (channels.count({module, name}) > 0)
            log_error("%s.%s: channel %s is already defined\n", 
                log_id(module), log_id(wire), name.c_str());

        auto &channel = channels[{module, name}];
        channel.module = module;
        channel.name = name;

        // Process channel direction

        std::string direction = wire->get_string_attribute(Attr::ChannelDirection);
        if (direction.empty())
            log_error("%s.%s: direction of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());

        if (direction == "in" || direction == "out") {
            channel.direction = direction == "in" ? CHANNEL_INPUT : CHANNEL_OUTPUT;
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
                    channel.dependencies.insert(dep);
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
                        channel.payloads.insert(module->wire(id));
            }
        }

        // Process channel valid/ready port

        std::string valid = wire->get_string_attribute(Attr::ChannelValid);
        if (!valid.empty()) {
            Wire *wire_valid = module->wire("\\" + valid);
            if (wire_valid == nullptr)
                log_error("%s.%s: valid port %s of channel %s does not exist\n", 
                    log_id(module), log_id(wire), valid.c_str(), name.c_str());

            channel.valid = wire_valid;
        }
        else {
            log_error("%s.%s: valid port of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());
        }

        std::string ready = wire->get_string_attribute(Attr::ChannelReady);
        if (!ready.empty()) {
            Wire *wire_ready = module->wire("\\" + ready);
            if (wire_ready == nullptr)
                log_error("%s.%s: ready port %s of channel %s does not exist\n", 
                    log_id(module), log_id(wire), ready.c_str(), name.c_str());

            channel.ready = wire_ready;
        }
        else {
            log_error("%s.%s: ready port of channel %s is required\n", 
                log_id(module), log_id(wire), name.c_str());
        }
    }
}

void RTLModelWorker::emit() {
    Module *wrapper = rewriter.wrapper();

    SigSpec finishing;

    // TODO: handle combinationally connected channels

    rewriter.define_wire("tick");

    auto mdl_clk = rewriter.clock("mdl_clk");
    auto mdl_rst = rewriter.wire("mdl_rst");
    auto scan_mode = rewriter.wire("scan_mode");

    SigBit non_scan_mode = wrapper->Not(NEW_ID, scan_mode->get(wrapper));

    SigBit mdl_clk_en = mdl_clk->getEnable();
    mdl_clk_en = wrapper->And(NEW_ID, mdl_clk_en, non_scan_mode);
    mdl_clk->setEnable(mdl_clk_en);

    auto tick = rewriter.wire("tick");

    for (auto &it : channels) {
        auto &channel = it.second;
        std::string &name = it.first.second;
        Cell *model_cell = rewriter.design().instance_of(channel.module);
        Module *module = model_cell->module;

        log("Emitting channel %s.%s\n", designinfo.hier_name_of(module).c_str(), name.c_str());

        SigSpec clk = mdl_clk->get(module);
        SigSpec rst = mdl_rst->get(module);

        SigSpec valid = module->addWire(module->uniquify("\\" + name + "_token_valid"));
        SigSpec ready = module->addWire(module->uniquify("\\" + name + "_token_ready"));

        model_cell->setPort(channel.valid->name, valid);
        model_cell->setPort(channel.ready->name, ready);

        SigSpec fire = module->And(NEW_ID, valid, ready);
        SigSpec done = module->addWire(module->uniquify("\\" + name + "_done"));

        // always @(posedge clk)
        //   if (rst || tick)
        //     done <= 1'b0;
        //   else if (fire)
        //     done <= 1'b1;
        module->addSdffe(NEW_ID,
            clk,
            fire,
            module->Or(NEW_ID, rst, tick->get(module)),
            State::S1,
            done,
            State::S0
        );

        if (channel.direction == CHANNEL_INPUT) {
            module->connect(valid, module->Not(NEW_ID, done));
        }
        else {
            module->connect(ready, module->Not(NEW_ID, done));
        }

        Wire *channel_finishing = module->addWire(module->uniquify("\\" + name + "_finishing"));
        module->connect(channel_finishing, module->Or(NEW_ID, fire, done));

        finishing.append(rewriter.promote(channel_finishing));
    }

    wrapper->connect(
        tick->get(wrapper),
        wrapper->ReduceAnd(NEW_ID, finishing)
    );

    // TODO: support multiple clocks

    for (auto &it : database.user_clocks) {
        auto clk = rewriter.clock(it.first);
        SigBit en = clk->getEnable();
        en = wrapper->And(NEW_ID, en, tick->get(wrapper));
        clk->setEnable(en);
    }
}

void RTLModelWorker::run() {
    analyze();
    emit();
}

PRIVATE_NAMESPACE_END

void TargetTransform::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing TargetTransform.\n");
    RTLModelWorker worker(database, rewriter);
    worker.run();
}
