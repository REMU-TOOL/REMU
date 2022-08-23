#ifndef _CIRCUIT_INFO_H_
#define _CIRCUIT_INFO_H_

#include <map>
#include <string>
#include <iterator>
#include <stdexcept>

#include "yaml-cpp/yaml.h"

namespace CircuitInfo {

class Node
{
    std::string name_;

public:

    virtual ~Node() {}

    std::string name() const { return name_; }
    virtual const char *type() const = 0;

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node;
        node["name"] = name_;
        node["type"] = type();
        return node;
    }

    virtual Node *dup() const = 0;

    static Node *from_yaml(const YAML::Node &node);

protected:

    Node(const std::string &name) : name_(name) {}
    Node(const YAML::Node &node) : name_(node["name"].as<std::string>()) {}
};

class Scope : public Node
{

    std::map<std::string, Node*> subnodes;

    void swap(Scope &other) noexcept
    {
        std::swap(subnodes, other.subnodes);
    }

public:

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
        for (auto it = y_subnodes.begin(); it != y_subnodes.end(); ++it) {
            const YAML::Node &y_subnode = *it;
            std::string n = y_subnode["name"].as<std::string>();
            subnodes[n] = Node::from_yaml(node);
        }
    }

    Scope(const std::string &name) : Node(name) {}

    virtual ~Scope()
    {
        for (auto &it : subnodes)
            delete it.second;
    }

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

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        for (auto &it : subnodes)
            node["subnodes"].push_back(it.second->to_yaml());
        return node;
    }

    virtual Node *dup() const
    {
        return new Scope(*this);
    }

    virtual const char *type() const { return "scope"; }

    Node *get(const std::string &name) const { return subnodes.at(name); }

    template <typename T> void set(const std::string &name, const T &subnode)
    {
        subnodes[name] = new T(subnode);
    }

    template <typename T> void set(const std::string &name, T &&subnode)
    {
        subnodes[name] = new T(subnode);
    }

    const Scope *follow(const std::vector<std::string> &path) const
    {
        const Scope *ptr = this;
        for (auto &name : path) {
            auto node = ptr->get(name);
            ptr = dynamic_cast<Scope*>(node);
            if (ptr == nullptr)
                throw std::bad_cast();
        }
        return ptr;
    }

    Scope *follow(const std::vector<std::string> &path)
    {
        return const_cast<Scope*>(follow(path));
    }

    Scope *create(const std::vector<std::string> &path)
    {
        Scope *ptr = this;
        for (auto &name : path) {
            if (!ptr->has(name))
                ptr->set(name, Scope(name));
            auto node = ptr->get(name);
            ptr = dynamic_cast<Scope*>(node);
            if (ptr == nullptr)
                throw std::bad_cast();
        }
        return ptr;
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

};

class Wire : public Node
{
    int width_;
    int start_offset_;
    bool upto_;

public:

    Wire(const YAML::Node &node) : Node(node),
        width_          (node["width"].as<int>()),
        start_offset_   (node["start_offset"].as<int>()),
        upto_           (node["upto"].as<bool>()) {}

    Wire(const std::string &name, int width, int start_offset, bool upto) : Node(name),
        width_(width), start_offset_(start_offset), upto_(upto) {}

    virtual const char *type() const { return "wire"; }
    int width() const { return width_; }
    int start_offset() const { return start_offset_; }
    bool upto() const { return upto_; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"] = width_;
        node["start_offset"] = start_offset_;
        node["upto"] = upto_;
        return node;
    }

    virtual Node *dup() const
    {
        return new Wire(*this);
    }
};

class Mem : public Node
{
    int width_;
    int depth_;
    int start_offset_;

public:

    Mem(const YAML::Node &node) : Node(node),
        width_          (node["width"].as<int>()),
        depth_          (node["depth"].as<int>()),
        start_offset_   (node["start_offset"].as<int>()) {}

    Mem(const std::string &name, int width, int depth, int start_offset) : Node(name),
        width_(width), depth_(depth), start_offset_(start_offset) {}

    virtual const char *type() const { return "mem"; }
    int width() const { return width_; }
    int depth() const { return depth_; }
    int start_offset() const { return start_offset_; }

    virtual YAML::Node to_yaml() const
    {
        YAML::Node node = Node::to_yaml();
        node["width"] = width_;
        node["depth"] = depth_;
        node["start_offset"] = start_offset_;
        return node;
    }

    virtual Node *dup() const
    {
        return new Mem(*this);
    }
};

};

#endif // #ifndef _CIRCUIT_INFO_H_
