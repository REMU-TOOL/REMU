#include "circuit_info.h"

using namespace CircuitInfo;

void Scope::add(const YAML::Node &subnode)
{
    Node *node = nullptr;
    auto type = static_cast<NodeType>(subnode["type"].as<int>());
    if (type == NODE_SCOPE)
        node = new Scope(subnode);
    else if (type == NODE_WIRE)
        node = new Wire(subnode);
    else if (type == NODE_MEM)
        node = new Mem(subnode);
    add(node);
}
