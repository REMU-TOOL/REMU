#ifndef _RUNTIME_INFO_H_
#define _RUNTIME_INFO_H_

#include <vector>
#include <map>
#include <unordered_map>
#include <queue>
#include <functional>

#include "emu_info.h"
#include "bitvector.h"
#include "emu_utils.h"

namespace REMU {

class Driver;

struct RTSignal
{
    std::string name;
    int width;
    bool output;
    uint32_t reg_offset;

    // serializable data begin

    std::map<uint64_t, BitVector> trace;

    // serializable data end

    std::queue<std::pair<uint64_t, BitVector>> trace_replay_q;

    RTSignal(const SysInfo::SignalInfo &info) :
        name(flatten_name(info.name)),
        width(info.width),
        output(info.output),
        reg_offset(info.reg_offset)
    {}
};

struct RTTrigger
{
    std::string name;
    int reg_index;

    // whether the trigger is enabled in record mode
    bool enabled;

    RTTrigger(const SysInfo::TriggerInfo &info) :
        name(flatten_name(info.name)),
        reg_index(info.index),
        enabled(true)
    {}
};

struct RTAXI
{
    std::string name;
    uint64_t size;
    uint32_t reg_offset;

    uint64_t assigned_base;
    uint64_t assigned_size;

    RTAXI(const SysInfo::AXIInfo &info) :
        name(flatten_name(info.name)),
        size(info.size),
        reg_offset(info.reg_offset),
        assigned_base(0),
        assigned_size(0)
    {}
};

template<typename T>
struct RTDatabase
{
    std::vector<T> m_data;
    std::unordered_map<std::string, int> m_map; // name -> index

    bool has(const std::string &name)
    {
        return m_map.find(name) != m_map.end();
    }

    int index_by_name(const std::string &name)
    {
        auto it = m_map.find(name);
        if (it == m_map.end())
            return -1;

        return it->second;
    }

    T& object_by_index(int index)
    {
        return m_data.at(index);
    }

    T& object_by_name(const std::string &name)
    {
        return object_by_index(index_by_name(name));
    }

    int count()
    {
        return m_data.size();
    }

    std::vector<T>& objects()
    {
        return m_data;
    }

    template<typename U>
    RTDatabase(const std::vector<U> &info)
    {
        m_data.reserve(info.size());
        int i = 0;
        for (auto &x : info) {
            auto it = m_data.insert(m_data.end(), x);
            m_map[it->name] = i++;
        }
    }
};

}

#endif
