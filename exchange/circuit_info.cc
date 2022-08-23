#include "circuit_info.h"

using namespace CircuitInfo;

Node *Node::from_yaml(const YAML::Node &node)
{
    Node *res = nullptr;
    std::string type = node["type"].as<std::string>();
    if (type == "scope")
        res = new Scope(node);
    else if (type == "wire")
        res = new Wire(node);
    else if (type == "mem")
        res = new Mem(node);
    return res;
}
