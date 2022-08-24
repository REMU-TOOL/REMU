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

class Node
{
    std::string name_;
    int id_;

protected:

    friend class Root;

    Node() : id_(0) {}
    Node(const std::string &name) : name_(name), id_(0) {}

    void assign_info(const std::string &name, int id)
    {
        name_ = name;
        id_ = id;
    }

public:

    Node(const YAML::Node &node)
    {
        name_   = node["name"].as<std::string>();
        id_     = node["name"].as<int>();
    }

    virtual ~Node() {}

    virtual Node *dup() const = 0;

    std::string name() const { return name_; }
    int id() const { return id_; }
    virtual NodeType type() const = 0;

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node;
        node["name"]    = name_;
        node["id"]      = id_;
        node["type"]    = static_cast<int>(type());
        return node;
    }
};

class Scope : public Node
{

    std::map<std::string, Node*> subnodes;

    void swap(Scope &other) noexcept
    {
        std::swap(subnodes, other.subnodes);
    }

public:

    void add(Node *subnode)
    {
        subnodes.insert(std::make_pair(subnode->name(), subnode));
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

class Root : public Scope
{
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
        node->assign_info(name, ++id_count);
        scope->add(node);
    }

    void add_node(const std::vector<std::string> &path, Node *node)
    {
        if (path.size() < 1)
            throw std::invalid_argument("empty path is not allowed");
        Scope *scope = create_hierarchy(path.begin(), path.end() - 1);
        node->assign_info(path.back(), ++id_count);
        scope->add(node);
    }

public:

    Root() {}

    Root(const YAML::Node &node);

    template <typename T> void add(const std::vector<std::string> &path, const T &subnode)
    {
        add_node(path, new T(subnode));
    }

    template <typename T> void add(const std::vector<std::string> &path, T &&subnode)
    {
        add_node(path, new T(subnode));
    }
};

class Wire : public Node
{
    int width_;
    int start_offset_;
    bool upto_;

public:

    Wire(const YAML::Node &node) : Node(node)
    {
        width_          = node["width"].as<int>();
        start_offset_   = node["start_offset"].as<int>();
        upto_           = node["upto"].as<bool>();
    }

    Wire(int width, int start_offset, bool upto) :
        width_(width), start_offset_(start_offset), upto_(upto) {}

    virtual Node *dup() const
    {
        return new Wire(*this);
    }

    virtual NodeType type() const { return NODE_WIRE; }
    int width() const { return width_; }
    int start_offset() const { return start_offset_; }
    bool upto() const { return upto_; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"]           = width_;
        node["start_offset"]    = start_offset_;
        node["upto"]            = upto_;
        return node;
    }
};

class Mem : public Node
{
    int width_;
    int depth_;
    int start_offset_;

public:

    Mem(const YAML::Node &node) : Node(node)
    {
        width_          = node["width"].as<int>();
        depth_          = node["depth"].as<int>();
        start_offset_   = node["start_offset"].as<int>();
    }

    Mem(int width, int depth, int start_offset) :
        width_(width), depth_(depth), start_offset_(start_offset) {}

    virtual Node *dup() const
    {
        return new Mem(*this);
    }

    virtual NodeType type() const { return NODE_MEM; }
    int width() const { return width_; }
    int depth() const { return depth_; }
    int start_offset() const { return start_offset_; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"]           = width_;
        node["depth"]           = depth_;
        node["start_offset"]    = start_offset_;
        return node;
    }
};

};

#endif // #ifndef _CIRCUIT_INFO_H_
