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

struct InterfaceWorker {

    EmulationRewriter &rewriter;
    DesignInfo &designinfo;
    HierconnBuilder hierconn;

    void process_extern_intf(Module *module);

    void run();

    InterfaceWorker(EmulationRewriter &rewriter)
        : rewriter(rewriter), designinfo(rewriter.design()), hierconn(designinfo) {}

};

void InterfaceWorker::process_extern_intf(Module *module) {
    Module *wrapper = rewriter.wrapper();

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Check if external interface attribute is set
        std::string intf = wire->get_string_attribute(Attr::ExternIntf);
        if (intf.empty())
            continue;

        log_assert(wire->port_input ^ wire->port_output);

        // TODO: process type attributes

        std::string newname = designinfo.hier_name_of(wire, rewriter.wrapper());
        newname = simple_id_escape(newname);

        log("Exposing port %s as %s\n", designinfo.hier_name_of(wire).c_str(), newname.c_str());

        // Create a connection

        Wire *top_wire = wrapper->addWire("\\" + newname, wire->width);
        top_wire->port_input = wire->port_input;
        top_wire->port_output = wire->port_output;

        if (wire->port_input)
            hierconn.connect(wire, top_wire, wire->name.substr(1));
        else
            hierconn.connect(top_wire, wire, wire->name.substr(1));
    }

    wrapper->fixup_ports();
}

void InterfaceWorker::run() {
    std::queue<Module *> work_queue;

    // Add top module to work queue
    work_queue.push(rewriter.wrapper());

    while (!work_queue.empty()) {
        // Get the first module from work queue
        Module *module = work_queue.front();
        work_queue.pop();

        process_extern_intf(module);

        // Add children modules to work queue
        for (Module *sub : rewriter.design().children_of(module))
            work_queue.push(sub);
    }
}

PRIVATE_NAMESPACE_END

void InterfaceTransform::execute(EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing InterfaceTransform.\n");
    InterfaceWorker worker(rewriter);
    worker.run();
}
