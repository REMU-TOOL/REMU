#include "kernel/yosys.h"

#include "emu.h"
#include "attr.h"
#include "interface.h"

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

PRIVATE_NAMESPACE_END

void ExportInterfaceWorker::process_module(Module *module) {
    Module *top = designinfo.top();

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        // Check if external interface attribute is set
        std::string intf = wire->get_string_attribute(Attr::ExternIntf);
        if (intf.empty())
            continue;

        log_assert(wire->port_input ^ wire->port_output);

        // TODO: process type attributes

        std::string newname = designinfo.hier_name_of(wire, top);
        newname = simple_id_escape(newname);

        log("Exposing port %s as %s\n", designinfo.hier_name_of(wire).c_str(), newname.c_str());

        // Create a connection

        Wire *top_wire = top->addWire("\\" + newname, wire->width);
        top_wire->port_input = wire->port_input;
        top_wire->port_output = wire->port_output;

        if (wire->port_input)
            hierconn.connect(wire, top_wire, wire->name.substr(1));
        else
            hierconn.connect(top_wire, wire, wire->name.substr(1));
    }

    top->fixup_ports();
}

void ExportInterfaceWorker::run()
{
    log_header(designinfo.design(), "Exporting interfaces.\n");

    std::queue<Module *> work_queue;

    // Add top module to work queue
    work_queue.push(designinfo.top());

    while (!work_queue.empty()) {
        // Get the first module from work queue
        Module *module = work_queue.front();
        work_queue.pop();

        process_module(module);

        // Add children modules to work queue
        for (Module *sub : designinfo.children_of(module))
            work_queue.push(sub);
    }
}
