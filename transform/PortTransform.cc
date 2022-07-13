#include "kernel/yosys.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

#include <queue>

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

std::string simple_id_escape(std::string name) {
    for (char &c : name) {
        if (c >= '0' && c <= '9')
            continue;
        if (c >= 'A' && c <= 'Z')
            continue;
        if (c >= 'a' && c <= 'z')
            continue;
        c = '_';
    }
    return name;
}

struct PortWorker {

    EmulationRewriter &rewriter;
    DesignInfo &designinfo;
    HierconnBuilder hierconn;

    void process_dut_clock_reset(Module *module);
    void process_dut_reset(Module *module);
    void process_common_port(Module *module);
    void process_extern_intf(Module *module);

    void run();

    PortWorker(EmulationRewriter &rewriter)
        : rewriter(rewriter), designinfo(rewriter.design()), hierconn(designinfo) {}

};

void PortWorker::process_dut_clock_reset(Module *module) {
    std::vector<Wire *> clocks, resets;

    for (Wire *wire : module->wires()) {
        if (wire->get_bool_attribute(Attr::DUTClock))
            clocks.push_back(wire);
        else if (wire->get_bool_attribute(Attr::DUTReset))
            resets.push_back(wire);
    }

    Module *wrapper = rewriter.wrapper();
    Wire *run_mode = rewriter.wire("run_mode")->get(wrapper);

    for (Wire *clk : clocks) {
        std::string name = designinfo.hier_name_of(clk, rewriter.target());
        name = simple_id_escape(name);
        rewriter.define_clock(name);

        auto dut_clk = rewriter.clock(name);
        SigBit en = dut_clk->getEnable();
        en = wrapper->And(NEW_ID, en, run_mode);
        dut_clk->setEnable(en);

        Module *module = clk->module;
        module->connect(clk, dut_clk->get(module));

        rewriter.database().dutclocks[name] = {};
    }

    for (Wire *rst : resets) {
        std::string name = designinfo.hier_name_of(rst, rewriter.target());
        name = simple_id_escape(name);
        rewriter.define_wire(name, 1, PORT_INPUT);

        auto dut_rst = rewriter.wire(name);

        Module *module = rst->module;
        module->connect(rst, dut_rst->get(module));

        rewriter.database().dutresets[name] = {};
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

        log("Connecting %s to %s\n", designinfo.hier_name_of(wire).c_str(), name.c_str());

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

void PortWorker::run() {
    std::queue<Module *> work_queue;

    // Add top module to work queue
    work_queue.push(rewriter.wrapper());

    while (!work_queue.empty()) {
        // Get the first module from work queue
        Module *module = work_queue.front();
        work_queue.pop();

        process_dut_clock_reset(module);
        process_common_port(module);

        // Add children modules to work queue
        for (Module *sub : rewriter.design().children_of(module))
            work_queue.push(sub);
    }
}

PRIVATE_NAMESPACE_END

void PortTransform::execute(EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing PortTransform.\n");
    PortWorker worker(rewriter);
    worker.run();
}
