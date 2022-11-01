#ifndef _EMU_HIER_H_
#define _EMU_HIER_H_

#include "kernel/yosys.h"

#include "dag.h"

namespace Emu {

struct Hierarchy : public DAG<Yosys::IdString, Yosys::IdString>
{
    Yosys::dict<Yosys::IdString, int> node_map; // module name -> module node
    int root;

    void addModule(Yosys::Module *module);
    void addInst(Yosys::Cell *inst);

    Node& node(Yosys::IdString name) { return nodes.at(node_map.at(name)); }
    Node& node(Yosys::Module *module) { return node(module->name); }
    Node& rootNode() { return nodes.at(root); }

    // traverse the hierarchy in post-order
    TraverseRange traverse() { return DAG::traverse(rootNode()); }

    Hierarchy(Yosys::Design *design);
};

}

#endif //#ifndef _EMU_HIER_H_
