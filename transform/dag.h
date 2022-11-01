#ifndef _DAG_H_
#define _DAG_H_

#include <type_traits>
#include <vector>
#include <limits>
#include <stdexcept>
#include <algorithm>

template<typename NT = void, typename ET = void>
struct DAG
{
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

    template<typename, typename = void>
    struct __MaybeData {};

    template<typename T>
    struct __MaybeData<T, typename std::enable_if<!std::is_void<T>::value>::type>
    {
        T data;
    };

    struct Node : public __MaybeData<NT>
    {
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

        Node(DAG *dag) : dag(dag) {}

        Edge& inEdge(int index) { return dag->edges.at(in.at(index)); }
        Edge& outEdge(int index) { return dag->edges.at(out.at(index)); }

        EdgeRange inEdges() { return EdgeRange(&dag->edges, &in); }
        EdgeRange outEdges() { return EdgeRange(&dag->edges, &out); }

        int firstOut() { return out.empty() ? -1 : out.at(0); }
    };

    struct Edge : public __MaybeData<ET>
    {
        DAG *dag;
        int from;               // parent node index
        int to;                 // child node index
        int index;              // edge index
        int next;               // next edge index from the same node

        Edge(DAG *dag) : dag(dag) {}

        Node& fromNode() { return dag->nodes.at(from); }
        Node& toNode() { return dag->nodes.at(to); }

        Edge& nextEdge() { return dag->edges.at(next); }
    };

    std::vector<Node> nodes;
    std::vector<Edge> edges;

    Node& addNode()
    {
        if (nodes.size() >= std::numeric_limits<int>::max())
            throw std::overflow_error("node count limit exceeded");

        auto it = nodes.emplace(nodes.end(), this);
        it->index   = it - nodes.begin();

        return *it;
    }

    Edge& addEdge(int from, int to)
    {
        if (edges.size() >= std::numeric_limits<int>::max())
            throw std::overflow_error("edge count limit exceeded");

        auto it = edges.emplace(edges.end(), this);
        it->from    = from;
        it->to      = to;
        it->index   = it - edges.begin();
        it->next    = -1;

        auto &out_edges = nodes.at(it->from).out;
        if (!out_edges.empty())
            edges.at(out_edges.back()).next = it->index;
        out_edges.push_back(it->index);

        nodes.at(it->to).in.push_back(it->index);

        return *it;
    }

    Edge& addEdge(Node &from, Node &to)
    {
        return addEdge(from.index, to.index);
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,NT>::value>::type>
    Node& addNode(const T &data)
    {
        auto &res = addNode();
        res.data = data;
        return res;
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,NT>::value>::type>
    Node& addNode(NT &&data)
    {
        auto &res = addNode();
        res.data = data;
        return res;
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,ET>::value>::type>
    Edge& addEdge(const T &data, int from, int to)
    {
        auto &res = addEdge(from, to);
        res.data = data;
        return res;
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,ET>::value>::type>
    Edge& addEdge(T &&data, int from, int to)
    {
        auto &res = addEdge(from, to);
        res.data = data;
        return res;
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,ET>::value>::type>
    Edge& addEdge(const T &data, Node &from, Node &to)
    {
        return addEdge(data, from.index, to.index);
    }

    template<typename T, typename = typename std::enable_if<std::is_same<T,ET>::value>::type>
    Edge& addEdge(T &&data, Node &from, Node &to)
    {
        return addEdge(data, from.index, to.index);
    }

    struct TraverseRange
    {
        Node *root;
        TraverseRange(Node *root) : root(root) {}
        Iterator<Path, PathIteratorOps> begin() { return PathIteratorOps(root); }
        Iterator<Path, PathIteratorOps> end() { return PathIteratorOps(); }
    };

    // traverse the hierarchy in post-order
    TraverseRange traverse(Node &root) { return &root; }

    struct SortRange
    {
        std::vector<Node> *vector_p;
        std::vector<int> sorted;
        Iterator<Node, IndirectIteratorOps<Node>> begin() { return IndirectIteratorOps<Node>(vector_p, sorted.begin()); }
        Iterator<Node, IndirectIteratorOps<Node>> end() { return IndirectIteratorOps<Node>(vector_p, sorted.end()); }
        Iterator<Node, IndirectIteratorOps<Node>> rbegin() { return IndirectIteratorOps<Node>(vector_p, sorted.rbegin()); }
        Iterator<Node, IndirectIteratorOps<Node>> rend() { return IndirectIteratorOps<Node>(vector_p, sorted.rend()); }
        SortRange(decltype(vector_p) vector_p, decltype(sorted) &&sorted)
            : vector_p(vector_p), sorted(sorted) {}
    };

    struct DFSWorker
    {
        DAG *dag;
        std::vector<bool> visiting, visited;
        std::vector<int> sorted;
        std::vector<int> node_stack, edge_stack;

        bool enter(int node);
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

template<typename NT, typename ET>
inline void DAG<NT,ET>::PathIteratorOps::enter(Node *node)
{
    while (!node->out.empty()) {
        cur.push_back(&node->outEdge(0));
        node = &cur.back()->toNode();
    }
}

template<typename NT, typename ET>
inline void DAG<NT,ET>::PathIteratorOps::next()
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

template<typename NT, typename ET>
inline bool DAG<NT,ET>::DFSWorker::enter(int node)
{
    while (true) {
        node_stack.push_back(node);

        if (visited.at(node))
            return true;

        if (visiting.at(node))
            return false;

        visiting[node] = true;

        int edge = dag->nodes.at(node).firstOut();
        if (edge < 0)
            break;

        edge_stack.push_back(edge);
        node = dag->edges.at(edge).to;
    }

    return true;
}

template<typename NT, typename ET>
inline bool DAG<NT,ET>::DFSWorker::sort(bool reversed)
{
    int n = dag->nodes.size();
    visiting.assign(n, false);
    visited.assign(n, false);
    sorted.clear();
    node_stack.clear();
    edge_stack.clear();

    for (int root = 0; root < n; root++) {
        if (visited.at(root))
            continue;

        if (!enter(root))
            return false;

        while (true) {
            int node = node_stack.back();
            node_stack.pop_back();

            // assert(node_stack.size() == edge_stack.size());

            visiting[node] = false;
            visited[node] = true;
            sorted.push_back(node);

            if (node_stack.empty())
                break;

            int edge = edge_stack.back();
            edge_stack.pop_back();
            edge = dag->edges.at(edge).next;

            if (edge >= 0) {
                edge_stack.push_back(edge);
                if (!enter(dag->edges.at(edge).to))
                    return false;
            }
        }
    }

    if (!reversed)
        std::reverse(sorted.begin(), sorted.end());

    return true;
}

#endif //#ifndef _DAG_H_
