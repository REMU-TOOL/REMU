#ifndef _EMU_HIER_H_
#define _EMU_HIER_H_

#include "kernel/yosys.h"

namespace Emu {

namespace Hier {

struct Hierarchy;
struct Node;
struct Edge;

using Path = std::vector<Edge*>;

template<typename T, typename OPS>
struct Iterator
{
    using iterator_category = std::forward_iterator_tag;
    using value_type = T;
    using difference_type = std::ptrdiff_t;
    using pointer = T*;
    using reference = T&;
    OPS ops;

    Iterator() {}
    Iterator(const OPS &ops) : ops(ops) {}
    Iterator(OPS &&ops) : ops(ops) {}

    reference operator*() const { return ops.get(); }
    pointer operator->() { return &ops.get(); }

    Iterator& operator++() { ops.next(); return *this; }
    Iterator operator++(int) { Iterator<T, OPS> tmp(*this); ++(*this); return tmp; }

    bool operator==(const Iterator &other) const { return ops == other.ops; }
    bool operator!=(const Iterator &other) const { return !(*this == other); }
};

template<typename T>
struct IndirectIteratorOps
{
    std::vector<T> *vector_p;
    std::vector<int>::iterator it;

    IndirectIteratorOps(decltype(vector_p) vector_p, decltype(it) it)
        : vector_p(vector_p), it(it) {}

    T& get() const {
        return vector_p->at(*it);
    }

    void next() {
        ++it;
    }

    bool operator==(const IndirectIteratorOps<T> &other) const {
        return vector_p == other.vector_p && it == other.it;
    }
};

struct PathIteratorOps
{
    Path cur;
    bool empty;

    void enter(Node *node);
    PathIteratorOps() : empty(true) {}
    PathIteratorOps(Node *root) : empty(false) { enter(root); }
    Path& get() const { return const_cast<Path&>(cur); } // const_cast is a hack and the user should not modify the referenced path
    void next();
    bool operator==(const PathIteratorOps &other) const { return cur == other.cur && empty == other.empty; }
};

struct Hierarchy
{
    std::vector<Node> nodes;
    std::vector<Edge> edges;
    Yosys::dict<Yosys::IdString, int> node_map; // module name -> module node
    int root;

    void addModule(Yosys::Module *module);
    void addInst(Yosys::Cell *inst);

    Node& node(Yosys::IdString name) { return nodes.at(node_map.at(name)); }
    Node& node(Yosys::Module *module) { return node(module->name); }
    Node& rootNode() { return nodes.at(root); }

    struct TraverseRange {
        Node *root;
        TraverseRange(Node *root) : root(root) {}
        Iterator<Path, PathIteratorOps> begin() { return PathIteratorOps(root); }
        Iterator<Path, PathIteratorOps> end() { return PathIteratorOps(); }
    };

    // traverse the hierarchy in post-order
    TraverseRange traverse() { return &this->rootNode(); }

    Hierarchy(Yosys::Design *design);
};

struct Node
{
    Hierarchy *hier_p;
    Yosys::IdString name;   // module name
    std::vector<int> in;    // edge indices from parents
    std::vector<int> out;   // edge indices from children
    int index;              // node index

    struct EdgeRange
    {
        std::vector<Edge> *vector_p;
        std::vector<int> *indices_p;
        Iterator<Edge, IndirectIteratorOps<Edge>> begin() { return IndirectIteratorOps<Edge>(vector_p, indices_p->begin()); }
        Iterator<Edge, IndirectIteratorOps<Edge>> end() { return IndirectIteratorOps<Edge>(vector_p, indices_p->end()); }
        EdgeRange(decltype(vector_p) vector_p, decltype(indices_p) indices_p)
            : vector_p(vector_p), indices_p(indices_p) {}
    };

    Node(Hierarchy *hier_p) : hier_p(hier_p) {}

    Edge& inEdge(int index) { return hier_p->edges.at(in.at(index)); }
    Edge& outEdge(int index) { return hier_p->edges.at(out.at(index)); }

    EdgeRange inEdges() { return EdgeRange(&hier_p->edges, &in); }
    EdgeRange outEdges() { return EdgeRange(&hier_p->edges, &out); }
};

struct Edge
{
    Hierarchy *hier_p;
    Yosys::IdString name;   // instantiation (cell) name
    int from;               // parent node index
    int to;                 // child node index
    int index;              // edge index
    int next;               // next edge index from the same node

    Edge(Hierarchy *hier_p) : hier_p(hier_p) {}

    Node& fromNode() { return hier_p->nodes.at(from); }
    Node& toNode() { return hier_p->nodes.at(to); }

    Edge& nextEdge() { return hier_p->edges.at(next); }
};

inline void PathIteratorOps::enter(Node *node)
{
    while (!node->out.empty()) {
        cur.push_back(&node->outEdge(0));
        node = &cur.back()->toNode();
    }
}

inline void PathIteratorOps::next()
{
    if (cur.empty()) {
        empty = true;
        return;
    }

    Edge *&last = cur.back();
    if (last->next >= 0) {
        last = &last->nextEdge();
        enter(&last->toNode());
    }
    else {
        cur.pop_back();
    }
}

}; // namespace Hier

}; // namespace Emu

#endif //#ifndef _EMU_HIER_H_
