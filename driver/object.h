#ifndef _REMU_DRIVER_OBJECT_H_
#define _REMU_DRIVER_OBJECT_H_

#include <cstdint>

#include <string>
#include <vector>
#include <unordered_map>

namespace REMU {

struct SignalObject
{
    int index;
    std::string name;
    int width;
    bool output;
    uint32_t reg_offset;
};

struct TriggerObject
{
    int index;
    std::string name;
    int reg_index;
};

struct AXIObject
{
    int index;
    std::string name;
    uint64_t size;
    uint32_t reg_offset;
    uint64_t assigned_offset;
    uint64_t assigned_size;
};

template<typename T>
class ObjectManager
{
    std::vector<T> obj_list;
    std::unordered_map<std::string, int> name_map;

public:

    void add(const T &obj)
    {
        std::string name = obj.name;
        int index = obj_list.size();
        obj.index = index;
        obj_list.push_back(obj);
        name_map.insert({name, index});
    }

    void add(T &&obj)
    {
        std::string name = obj.name;
        int index = obj_list.size();
        obj.index = index;
        obj_list.push_back(std::move(obj));
        name_map.insert({name, index});
    }

    int lookup(const std::string &name)
    {
        if (name_map.find(name) == name_map.end())
            return -1;
        return name_map.at(name);
    }

    T& get(int index) { return obj_list.at(index); }
    T& get(const std::string name) { return get(lookup(name)); }

    int size() { return obj_list.size(); }

    typename std::vector<T>::iterator begin() { return obj_list.begin(); }
    typename std::vector<T>::iterator end() { return obj_list.end(); }
};

}

#endif
