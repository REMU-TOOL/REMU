#ifndef _CIRCUIT_INFO_H_
#define _CIRCUIT_INFO_H_

#include <map>
#include <string>
#include <iterator>
#include <stdexcept>

#include "yaml-cpp/yaml.h"

namespace CircuitInfo {

enum NodeType {
    NODE_SCOPE,
    NODE_WIRE,
    NODE_MEM,
};

struct Node
{
    std::string name;
    int id;

    Node() : id(0) {}

    Node(const YAML::Node &node)
    {
        name    = node["name"].as<std::string>();
        id      = node["name"].as<int>();
    }

    virtual ~Node() {}
    virtual Node *dup() const = 0;
    virtual NodeType type() const = 0;

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node;
        node["name"]    = name;
        node["id"]      = id;
        node["type"]    = static_cast<int>(type());
        return node;
    }
};

struct Scope : public Node
{

private:

    std::map<std::string, Node*> subnodes;

    void swap(Scope &other) noexcept
    {
        std::swap(subnodes, other.subnodes);
    }

public:

    void add(Node *subnode)
    {
        subnodes.insert(std::make_pair(subnode->name, subnode));
    }

    void add(const YAML::Node &subnode);

    Scope(const Scope &other) : Node(other)
    {
        for (auto &it : other.subnodes)
            subnodes[it.first] = it.second->dup();
    }

    Scope(Scope &&other) noexcept : Node(other)
    {
        swap(other);
    }

    Scope(const YAML::Node &node) : Node(node)
    {
        auto &y_subnodes = node["subnodes"];
        for (auto it = y_subnodes.begin(); it != y_subnodes.end(); ++it)
            add(*it);
    }

    Scope() {}

    Scope &operator=(const Scope &other)
    {
        if (this == &other)
            return *this;

        Scope temp(other);
        swap(temp);
        return *this;
    }

    Scope &operator=(Scope &&other) noexcept
    {
        Scope temp(std::move(other));
        swap(temp);
        return *this;
    }

    virtual ~Scope()
    {
        for (auto &it : subnodes)
            delete it.second;
    }

    virtual Node *dup() const
    {
        return new Scope(*this);
    }

    virtual NodeType type() const { return NODE_SCOPE; }

    const Node *get(const std::string &name) const { return subnodes.at(name); }
    Node *get(const std::string &name) { return subnodes.at(name); }

    const Node *get(const std::vector<std::string> &path) const
    {
        const Node *node = this;
        for (auto &name : path) {
            auto scope = dynamic_cast<const Scope*>(node);
            if (scope == nullptr)
                throw std::bad_cast();
            node = scope->get(name);
        }
        return node;
    }

    Node *get(const std::vector<std::string> &path)
    {
        return const_cast<Node*>(get(path));
    }

    bool has(const std::string &name) const
    {
        return subnodes.find(name) != subnodes.end();
    }

    decltype(subnodes)::iterator        begin()         { return subnodes.begin(); }
    decltype(subnodes)::iterator        end()           { return subnodes.end(); }
    decltype(subnodes)::const_iterator  begin() const   { return subnodes.begin(); }
    decltype(subnodes)::const_iterator  end() const     { return subnodes.end(); }
    decltype(subnodes)::const_iterator  cbegin() const  { return subnodes.begin(); }
    decltype(subnodes)::const_iterator  cend() const    { return subnodes.end(); }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        for (auto &it : subnodes)
            node["subnodes"].push_back(it.second->to_yaml());
        return node;
    }
};

struct Root : public Scope
{
private:

    int id_count = 0; // start from 1

    template <typename T> Scope *create_hierarchy(const T &path_begin, const T &path_end)
    {
        Scope *scope = this;
        for (auto it = path_begin; it != path_end; it++) {
            auto &name = *it;
            if (!scope->has(name))
                add_node(scope, name, new Scope);
            auto node = scope->get(name);
            scope = dynamic_cast<Scope*>(node);
            if (scope == nullptr)
                throw std::bad_cast();
        }
        return scope;
    }

    void add_node(Scope *scope, const std::string &name, Node *node)
    {
        node->name = name;
        node->id = ++id_count;
        scope->add(node);
    }

    void add_node(const std::vector<std::string> &path, Node *node)
    {
        if (path.size() < 1)
            throw std::invalid_argument("empty path is not allowed");
        Scope *scope = create_hierarchy(path.begin(), path.end() - 1);
        add_node(scope, path.back(), node);
    }

public:

    Root() {}
    Root(const YAML::Node &node) : Scope(node) {}

    template <typename T> void add(const std::vector<std::string> &path, const T &subnode)
    {
        add_node(path, new T(subnode));
    }

    template <typename T> void add(const std::vector<std::string> &path, T &&subnode)
    {
        add_node(path, new T(subnode));
    }
};

struct Wire : public Node
{
    int width;
    int start_offset;
    bool upto;

    Wire(const YAML::Node &node) : Node(node)
    {
        width           = node["width"].as<int>();
        start_offset    = node["start_offset"].as<int>();
        upto            = node["upto"].as<bool>();
    }

    Wire(int width, int start_offset, bool upto) :
        width(width), start_offset(start_offset), upto(upto) {}

    virtual Node *dup() const
    {
        return new Wire(*this);
    }

    virtual NodeType type() const { return NODE_WIRE; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"]           = width;
        node["start_offset"]    = start_offset;
        node["upto"]            = upto;
        return node;
    }
};

struct Mem : public Node
{
    int width;
    int depth;
    int start_offset;

    Mem(const YAML::Node &node) : Node(node)
    {
        width           = node["width"].as<int>();
        depth           = node["depth"].as<int>();
        start_offset    = node["start_offset"].as<int>();
    }

    Mem(int width, int depth, int start_offset) :
        width(width), depth(depth), start_offset(start_offset) {}

    virtual Node *dup() const
    {
        return new Mem(*this);
    }

    virtual NodeType type() const { return NODE_MEM; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"]           = width;
        node["depth"]           = depth;
        node["start_offset"]    = start_offset;
        return node;
    }
};

};

#endif // #ifndef _CIRCUIT_INFO_H_
