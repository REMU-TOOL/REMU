#include "kernel/yosys.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

#include <queue>

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

std::string simple_hier_id(const std::vector<std::string> &hier) {
    std::ostringstream ss;
    bool is_first = true;
    for (auto &name : hier) {
        if (is_first)
            is_first = false;
        else 
            ss << '_';
        for (char c : name) {
            if (c >= '0' && c <= '9')
                ss << c;
            else if (c >= 'A' && c <= 'Z')
                ss << c;
            else if (c >= 'a' && c <= 'z')
                ss << c;
            else
                ss << '_';
        }
    }
    return ss.str();
}

struct PortWorker {

    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    DesignInfo &designinfo;
    HierconnBuilder hierconn;

    void process_user_sigs(Module *module);
    void process_dut_reset(Module *module);
    void process_common_port(Module *module);
    void process_fifo_port(Module *module);
    void run();

    PortWorker(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter), designinfo(rewriter.design()), hierconn(designinfo) {}

};

void PortWorker::process_user_sigs(Module *module) {
    std::vector<Wire *> clocks, resets, trigs;

    for (Wire *wire : module->wires()) {
        if (wire->get_bool_attribute(Attr::UserClock))
            clocks.push_back(wire);
        else if (wire->get_bool_attribute(Attr::UserReset))
            resets.push_back(wire);
        else if (wire->get_bool_attribute(Attr::UserTrig))
            trigs.push_back(wire);
    }

    Module *wrapper = rewriter.wrapper();
    Wire *run_mode = rewriter.wire("run_mode")->get(wrapper);

    for (Wire *clk : clocks) {
        ClockInfo info;
        info.name = designinfo.hier_name_of(clk, rewriter.wrapper());
        info.top_name = simple_hier_id(info.name);
        rewriter.define_clock(info.top_name);

        auto dut_clk = rewriter.clock(info.top_name);
        SigBit en = dut_clk->getEnable();
        en = wrapper->And(NEW_ID, en, run_mode);
        dut_clk->setEnable(en);

        Module *module = clk->module;
        module->connect(clk, dut_clk->get(module));

        database.user_clocks.push_back(info);
    }

    for (Wire *rst : resets) {
        ResetInfo info;
        info.name = designinfo.hier_name_of(rst, rewriter.wrapper());
        info.top_name = simple_hier_id(info.name);
        rewriter.define_wire(info.top_name, 1, PORT_INPUT);

        auto dut_rst = rewriter.wire(info.top_name);

        Module *module = rst->module;
        module->connect(rst, dut_rst->get(module));

        database.user_resets.push_back(info);
    }

    for (Wire *trig : trigs) {
        TrigInfo info;
        info.name = designinfo.hier_name_of(trig, rewriter.wrapper());
        info.top_name = simple_hier_id(info.name);
        info.desc = trig->get_string_attribute(Attr::UserTrigDesc);
        rewriter.define_wire(info.top_name, 1, PORT_OUTPUT);

        auto dut_trig = rewriter.wire(info.top_name);
        dut_trig->put(trig);

        database.user_trigs.push_back(info);
    }
}

void PortWorker::process_common_port(Module *module) {
    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Get common port attribute
        std::string name = wire->get_string_attribute(Attr::CommonPort);
        if (name.empty())
            continue;

        log_assert(wire->port_input ^ wire->port_output);

        // Create a connection in parent module

        auto port = rewriter.wire(name);
        Cell *inst_cell = rewriter.design().instance_of(module);
        Module *parent = inst_cell->module;

        Wire *parent_wire;
        if (wire->port_input) {
            parent_wire = port->get(parent);
        }
        else {
            parent_wire = parent->addWire(parent->uniquify(wire->name), wire->width);
            port->put(parent_wire);
        }

        inst_cell->setPort(wire->name, parent_wire);
    }
}

void PortWorker::process_fifo_port(Module *module) {
    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string name = wire->get_string_attribute(Attr::FifoPortName);
        if (name.empty())
            continue;

        FifoPortInfo info;
        info.name = designinfo.hier_name_of(module, rewriter.wrapper());
        info.name.push_back(name);
        info.top_name = simple_hier_id(info.name);

        info.type = wire->get_string_attribute(Attr::FifoPortType);
        if (info.type.empty())
            log_error("missing type in fifo port %s\n", info.top_name.c_str());

        if (info.type != "sink" && info.type != "source")
            log_error("wrong type in fifo port %s\n", info.top_name.c_str());

        bool is_output = info.type == "sink";

        std::string enable_attr = wire->get_string_attribute(Attr::FifoPortEnable);
        if (enable_attr.empty())
            log_error("missing enable port in fifo port %s\n", info.top_name.c_str());

        std::string data_attr = wire->get_string_attribute(Attr::FifoPortData);
        if (data_attr.empty())
            log_error("missing data port in fifo port %s\n", info.top_name.c_str());

        std::string flag_attr = wire->get_string_attribute(Attr::FifoPortFlag);
        if (flag_attr.empty())
            log_error("missing flag port in fifo port %s\n", info.top_name.c_str());

        Wire *wire_enable = module->wire("\\" + enable_attr);
        Wire *wire_data = module->wire("\\" + data_attr);
        Wire *wire_flag = module->wire("\\" + flag_attr);

        log_assert(wire_enable && wire_enable->width == 1);
        log_assert(wire_data);
        log_assert(wire_flag && wire_flag->width == 1);

        info.port_enable = simple_hier_id(designinfo.hier_name_of(wire_enable, rewriter.wrapper()));
        info.port_data = simple_hier_id(designinfo.hier_name_of(wire_data, rewriter.wrapper()));
        info.port_flag = simple_hier_id(designinfo.hier_name_of(wire_flag, rewriter.wrapper()));
        info.width = GetSize(wire_data);

        auto enable = rewriter.define_wire(info.port_enable, 1, PORT_INPUT);
        auto data = rewriter.define_wire(info.port_data, wire_data->width, is_output ? PORT_OUTPUT : PORT_INPUT);
        auto flag = rewriter.define_wire(info.port_flag, 1, PORT_OUTPUT);

        enable->get(wire_enable);
        if (is_output)
            data->put(wire_data);
        else
            data->get(wire_data);
        flag->put(wire_flag);

        database.fifo_ports.push_back(info);
    }
}

void PortWorker::run() {
    std::queue<Module *> work_queue;

    // Add top module to work queue
    work_queue.push(rewriter.wrapper());

    while (!work_queue.empty()) {
        // Get the first module from work queue
        Module *module = work_queue.front();
        work_queue.pop();

        process_user_sigs(module);
        process_common_port(module);
        process_fifo_port(module);

        // Add children modules to work queue
        for (Module *sub : rewriter.design().children_of(module))
            work_queue.push(sub);
    }
}

PRIVATE_NAMESPACE_END

void PortTransform::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing PortTransform.\n");
    PortWorker worker(database, rewriter);
    worker.run();
}
