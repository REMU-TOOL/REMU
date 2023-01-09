#include "kernel/yosys.h"

#include "interface.h"
#include "attr.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

PRIVATE_NAMESPACE_BEGIN

void sig_from_wire(AXI::Sig &sig, Wire *wire)
{
    if (!wire || wire->port_input == wire->port_output) {
        sig.width = 0;
        return;
    }
    sig.name = wire->name.str();
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

void InterfaceWorker::promote_axi_intfs(Module *module)
{
    std::vector<AXIIntfInfo> axi_intfs;

    for (auto portid : module->ports) {
        Wire *wire = module->wire(portid);

        std::string type = wire->get_string_attribute(Attr::AxiType);

        if (type != "axi4")
            continue;

        std::string name = wire->get_string_attribute(Attr::AxiName);

        AXIIntfInfo info;
        info.name = {name};
        info.port_name = name;
        info.axi = axi4_from_prefix(module, name);
        info.addr_space = wire->get_string_attribute(Attr::AxiAddrSpace);
        info.addr_pages = -1;

        info.axi.check();

        if (wire->has_attribute(Attr::AxiAddrPages))
            info.addr_pages = wire->attributes.at(Attr::AxiAddrPages).as_int();

        log("Identified %s %s interface %s with addr_space = %s, addr_pages = %d\n",
            info.axi.isFull() ? "AXI4" : "AXI4-lite",
            info.axi.isMaster() ? "master" : "slave",
            name.c_str(),
            info.addr_space.c_str(),
            info.addr_pages);

        axi_intfs.push_back(info);
    }

    // export subodule ports

    auto &node = hier.dag.findNode(module->name);
    for (auto &edge : node.outEdges()) {
        auto &child = edge.toNode();
        Cell *inst = module->cell(edge.name.second);

        for (auto &info : all_axi_intfs.at(child.name)) {
            AXIIntfInfo newinfo = info;
            newinfo.name.insert(newinfo.name.begin(), id2str(edge.name.second));
            newinfo.port_name = "EMU_AXI_" + join_string(newinfo.name, '_');
            newinfo.axi.setPrefix("\\" + newinfo.port_name);

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

                Wire *wire = module->addWire(new_it->name, new_it->width);
                wire->port_input = !new_it->output;
                wire->port_output = new_it->output;
                inst->setPort(sub_it->name, wire);
            }

            axi_intfs.push_back(newinfo);
        }
    }

    module->fixup_ports();

    all_axi_intfs[module->name] = axi_intfs;
}

void InterfaceWorker::run()
{
    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = hier.design->module(node.name);
        log("Processing module %s...\n", log_id(module));
        promote_axi_intfs(module);
    }

    IdString top = hier.dag.rootNode().name;
    database.axi_intfs = all_axi_intfs.at(top);
}
