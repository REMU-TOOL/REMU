#ifndef _REMU_INFO_H_
#define _REMU_INFO_H_

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
        std::vector<std::string> name;
        int index;
    };

    struct SignalInfo
    {
        std::vector<std::string> name;
        int width;
        bool output;
        std::string init; // for input signals
        uint32_t reg_offset;
    };

    struct TriggerInfo
    {
        std::vector<std::string> name;
        int index;
    };

    struct AXIInfo
    {
        std::vector<std::string> name;
        uint64_t size;
        uint32_t reg_offset;
    };

    struct TraceInfo
    {
        std::vector<std::string> name;
        std::string type;
        uint32_t reg_offset;
    };

    struct ModelInfo
    {
        std::vector<std::string> name;
        std::string type;
        std::map<std::string, std::string> params; // bitvector
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
    std::vector<ClockInfo> clock;
    std::vector<SignalInfo> signal;
    std::vector<TriggerInfo> trigger;
    std::vector<AXIInfo> axi;
    std::vector<ModelInfo> model;
    std::vector<ScanFFInfo> scan_ff;
    std::vector<ScanRAMInfo> scan_ram;

    void toJson(std::ostream &stream);
    static SysInfo fromJson(std::istream &stream);
};

} // namespace REMU

#endif // #ifndef _REMU_INFO_H_
