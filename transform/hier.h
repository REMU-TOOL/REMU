#ifndef _EMU_HIER_H_
#define _EMU_HIER_H_

#include "kernel/yosys.h"

namespace Emu {

struct Hierarchy
{
    struct Node;
    struct Edge;

    template<typename T>
    struct Iterator
    {
        using iterator_category = std::forward_iterator_tag;
        using value_type = T;
        using difference_type = std::ptrdiff_t;
        using pointer = T*;
        using reference = T&;
        std::vector<int>::iterator it;
        std::vector<T> *map_p;

        Iterator() : map_p(nullptr) {}
        Iterator(decltype(it) &&it, decltype(map_p) map_p) : it(it), map_p(map_p) {}

        reference operator*() const { return map_p->at(*it); }
        pointer operator->() { return &map_p->at(*it); }

        Iterator& operator++() { ++it; return *this; }
        Iterator operator++(int) { Iterator<T> tmp(*this); ++(*this); return tmp; }

        bool operator==(const Iterator &other) const { return it == other.it && map_p == other.map_p; }
        bool operator!=(const Iterator &other) const { return !(*this == other); }
    };

    template<typename T>
    struct Range
    {
        std::vector<int> *list_p;
        std::vector<T> *map_p;
        Range(decltype(list_p) list_p, decltype(map_p) map_p) : list_p(list_p), map_p(map_p) {}
        virtual ~Range() {}
        Iterator<T> begin() { return Iterator<T>(list_p->begin(), map_p); }
        Iterator<T> end() { return Iterator<T>(list_p->end(), map_p); }
    };

    template<typename T>
    struct RangeWithListStorage : Range<T>
    {
        std::vector<int> list;
        RangeWithListStorage(std::vector<int> &list, std::vector<T> *map_p) : Range<T>(&list, map_p), list(list) {}
    };

    std::vector<Node> nodes;
    std::vector<Edge> edges;
    Yosys::dict<Yosys::IdString, int> node_map; // module name -> module node
    int root = -1;

    void addModule(Yosys::Module *module);
    void addInst(Yosys::Cell *inst);

    Node& node(Yosys::IdString name) { return nodes.at(node_map.at(name)); }
    Node& node(Yosys::Module *module) { return node(module->name); }

    // Sort all nodes from leaves to root
    Range<Node> topoSort();

    Hierarchy(Yosys::Design *design);
};

struct Hierarchy::Node
{
    Hierarchy *hier_p;
    Yosys::IdString name;   // module name
    std::vector<int> in;    // edge indices from parents
    std::vector<int> out;   // edge indices from children
    int index;              // node index

    Node(Hierarchy *hier_p) : hier_p(hier_p) {}

    Hierarchy::Range<Edge> inEdges() { return Hierarchy::Range<Edge>(&in, &hier_p->edges); }
    Hierarchy::Range<Edge> outEdges() { return Hierarchy::Range<Edge>(&out, &hier_p->edges); }
};

struct Hierarchy::Edge
{
    Hierarchy *hier_p;
    Yosys::IdString name;   // instantiation (cell) name
    int from;               // parent node index
    int to;                 // child node index
    int index;              // edge index

    Edge(Hierarchy *hier_p) : hier_p(hier_p) {}

    Node& fromNode() { return hier_p->nodes.at(from); }
    Node& toNode() { return hier_p->nodes.at(to); }
};

};

#endif //#ifndef _EMU_HIER_H_
