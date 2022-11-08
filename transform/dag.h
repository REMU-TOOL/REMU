#ifndef _DAG_H_
#define _DAG_H_

#include <type_traits>
#include <vector>
#include <limits>
#include <stdexcept>
#include <algorithm>

/*
    NT: node data type
    ET: edge data type
    NKT: node key type
    EKT: edge key type
    NMT: node map type (from KT to int, may be void, must support operator[](NKT), at(NKT) and count(NKT))
    EMT: edge map type (from KT to int, may be void, must support operator[](EKT), at(EKT) and count(EKT))
*/

template<
    typename NT,
    typename ET,
    typename NKT,
    typename EKT,
    typename NMT = void,
    typename EMT = void
>
struct DAG
{
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
        Iterator(OPS &&ops) : ops(std::move(ops)) {}

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

    struct Node;
    struct Edge;

    struct Node
    {
        NKT name;
        NT data;
        DAG *dag;
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

        Edge& inEdge(int index) { return dag->edges.at(in.at(index)); }
        Edge& outEdge(int index) { return dag->edges.at(out.at(index)); }

        EdgeRange inEdges() { return EdgeRange(&dag->edges, &in); }
        EdgeRange outEdges() { return EdgeRange(&dag->edges, &out); }

        int firstOut() { return out.empty() ? -1 : out.at(0); }

        Node(const std::pair<NKT, NT> &value, DAG *dag) : name(value.first), data(value.second), dag(dag) {}
        Node(std::pair<NKT, NT> &&value, DAG *dag) : name(std::move(value.first)), data(std::move(value.second)), dag(dag) {}
    };

    struct Edge
    {
        EKT name;
        ET data;
        DAG *dag;
        int from;               // parent node index
        int to;                 // child node index
        int index;              // edge index
        int next;               // next edge index from the same node

        Node& fromNode() { return dag->nodes.at(from); }
        Node& toNode() { return dag->nodes.at(to); }

        Edge& nextEdge() { return dag->edges.at(next); }

        Edge(const std::pair<EKT, ET> &value, DAG *dag) : name(value.first), data(value.second), dag(dag) {}
        Edge(std::pair<EKT, ET> &&value, DAG *dag) : name(std::move(value.first)), data(std::move(value.second)), dag(dag) {}
    };

    template<typename T>
    struct __dummy_map
    {
        int dummy;
        int& operator[](const T &) { dummy = -1; return dummy; }
        int at(const T &) const { return -1; }
        size_t count(const T &) const { return 0; }
    };

    std::vector<Node> nodes;
    std::vector<Edge> edges;
    typename std::conditional<std::is_void<NMT>::value, __dummy_map<NKT>, NMT>::type node_map;
    typename std::conditional<std::is_void<EMT>::value, __dummy_map<EKT>, EMT>::type edge_map;

    void clear()
    {
        nodes.clear();
        edges.clear();
    }

    void __check_nodes()
    {
        if (nodes.size() >= std::numeric_limits<int>::max())
            throw std::overflow_error("node count limit exceeded");
    }

    void __check_edges()
    {
        if (edges.size() >= std::numeric_limits<int>::max())
            throw std::overflow_error("edge count limit exceeded");
    }

    Node& __post_add(const typename std::vector<Node>::iterator &it)
    {
        it->index   = it - nodes.begin();

        if (node_map.count(it->name))
            throw std::overflow_error("node name already exists");
        node_map[it->name] = it->index;

        return *it;
    }

    Edge& __post_add(const typename std::vector<Edge>::iterator &it, int from, int to)
    {
        it->from    = from;
        it->to      = to;
        it->index   = it - edges.begin();
        it->next    = -1;

        if (edge_map.count(it->name))
            throw std::overflow_error("edge name already exists");
        edge_map[it->name] = it->index;

        auto &out_edges = nodes.at(it->from).out;
        if (!out_edges.empty())
            edges.at(out_edges.back()).next = it->index;
        out_edges.push_back(it->index);

        nodes.at(it->to).in.push_back(it->index);

        return *it;
    }

    Node& addNode(const std::pair<NKT, NT> &value)
    {
        __check_nodes();
        return __post_add(nodes.emplace(nodes.end(), value, this));
    }

    Node& addNode(std::pair<NKT, NT> &&value)
    {
        __check_nodes();
        return __post_add(nodes.emplace(nodes.end(), std::move(value), this));
    }

    Edge& addEdge(const std::pair<EKT, ET> &value, int from, int to)
    {
        __check_edges();
        return __post_add(edges.emplace(edges.end(), value, this), from, to);
    }

    Edge& addEdge(std::pair<EKT, ET> &&value, int from, int to)
    {
        __check_edges();
        return __post_add(edges.emplace(edges.end(), std::move(value), this), from, to);
    }

    Node& findNode(const NKT &name)
    {
        static_assert(!std::is_void<NMT>::value, "findNode requires NMT != void");
        return nodes.at(node_map.at(name));
    }

    Edge& findEdge(const EKT &name)
    {
        static_assert(!std::is_void<EMT>::value, "findEdge requires EMT != void");
        return edges.at(edge_map.at(name));
    }

    struct SortRange
    {
        std::vector<Node> *vector_p;
        std::vector<int> sorted;
        Iterator<Node, IndirectIteratorOps<Node>> begin() { return IndirectIteratorOps<Node>(vector_p, sorted.begin()); }
        Iterator<Node, IndirectIteratorOps<Node>> end() { return IndirectIteratorOps<Node>(vector_p, sorted.end()); }
        Iterator<Node, IndirectIteratorOps<Node>> rbegin() { return IndirectIteratorOps<Node>(vector_p, sorted.rbegin()); }
        Iterator<Node, IndirectIteratorOps<Node>> rend() { return IndirectIteratorOps<Node>(vector_p, sorted.rend()); }
        SortRange(decltype(vector_p) vector_p, decltype(sorted) &&sorted)
            : vector_p(vector_p), sorted(std::move(sorted)) {}
    };

    struct DFSWorker
    {
        DAG *dag;
        std::vector<int> sorted;
        std::vector<int> node_stack, edge_stack;

        bool sort(bool reversed);

        DFSWorker(DAG *dag) : dag(dag) {}
    };

    SortRange topoSort(bool reversed = false)
    {
        DFSWorker worker(this);
        if (!worker.sort(reversed))
            throw std::range_error("circular path found in DAG");
        return SortRange(&nodes, std::move(worker.sorted));
    }
};

template<typename NT, typename ET, typename NKT, typename NMT, typename EKT, typename EMT>
inline bool DAG<NT,ET,NKT,NMT,EKT,EMT>::DFSWorker::sort(bool reversed)
{
    // visiting.at(n) == node_stack contains n
    std::vector<bool> visiting, visited;
    int n = dag->nodes.size();
    visiting.assign(n, false);
    visited.assign(n, false);
    sorted.clear();
    node_stack.clear();
    edge_stack.clear();
    sorted.reserve(n);

    for (int root = 0; root < n; root++) {
        if (visited.at(root))
            continue;

        edge_stack.push_back(-1); // dummy edge
        node_stack.push_back(root);
        visiting[root] = true;
        int edge = -1;

        while (!node_stack.empty()) {
            int node = node_stack.back();

            if (edge < 0)
                edge = dag->nodes.at(node).firstOut();
            else
                edge = dag->edges.at(edge).next;

            if (edge < 0) {
                // all edges from this node are visited
                visiting[node] = false;
                visited[node] = true;
                sorted.push_back(node);
                node_stack.pop_back();
                edge = edge_stack.back();
                edge_stack.pop_back();
            }
            else {
                // visit child node
                int next_node = dag->edges.at(edge).to;
                if (!visited.at(next_node)) {
                    edge_stack.push_back(edge);
                    node_stack.push_back(next_node);
                    if (visiting.at(next_node))
                        return false;
                    visiting[next_node] = true;
                    edge = -1;
                }
            }
        }
    }

    if (!reversed)
        std::reverse(sorted.begin(), sorted.end());

    return true;
}

#endif //#ifndef _DAG_H_
