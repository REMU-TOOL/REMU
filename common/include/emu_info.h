#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <string>
#include <vector>
#include <map>
#include <iostream>

namespace REMU {

struct SysInfo
{
    struct WireInfo
    {
        int width;
        int start_offset;
        bool upto;
        bool init_zero;
        std::string init_data; // valid if !init_zero
    };

    struct RAMInfo
    {
        int width;
        int depth;
        int start_offset;
        bool init_zero;
        std::string init_data; // valid if !init_zero
        bool dissolved;
    };

    struct ClockInfo
    {
        int index;
    };

    struct SignalInfo
    {
        int width;
        bool output;
        uint32_t reg_offset;
    };

    struct TriggerInfo
    {
        int index;
    };

    struct AXIInfo
    {
        uint64_t size;
        uint32_t reg_offset;
    };

    struct ModelInfo
    {
        std::string type;
        std::map<std::string, std::string> str_params;
        std::map<std::string, int> int_params;
    };

    struct ScanFFInfo
    {
        std::vector<std::string> name; // empty if the FF is not from source code
        int width;
        int offset;
    };

    struct ScanRAMInfo
    {
        std::vector<std::string> name;
        int width;
        int depth;
    };

    std::map<std::vector<std::string>, WireInfo> wire;
    std::map<std::vector<std::string>, RAMInfo> ram;
    std::map<std::vector<std::string>, ClockInfo> clock;
    std::map<std::vector<std::string>, SignalInfo> signal;
    std::map<std::vector<std::string>, TriggerInfo> trigger;
    std::map<std::vector<std::string>, AXIInfo> axi;
    std::map<std::vector<std::string>, ModelInfo> model;

    std::vector<ScanFFInfo> scan_ff;
    std::vector<ScanRAMInfo> scan_ram;
};

std::ostream& operator<<(std::ostream &stream, const SysInfo &info);
std::istream& operator>>(std::istream &stream, SysInfo &info);

struct PlatInfo
{
    std::string mem_type;
    uint64_t mem_base;
    uint64_t mem_size;
    std::string reg_type;
    uint64_t reg_base;
    uint64_t reg_size;
};

std::ostream& operator<<(std::ostream &stream, const PlatInfo &info);
std::istream& operator>>(std::istream &stream, PlatInfo &info);

} // namespace REMU

#endif // #ifndef _CONFIG_H_
