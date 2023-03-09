#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "emu_info.h"
#include "axi.h"

namespace REMU {

struct ClockPort
{
    std::vector<std::string> name;
    std::string port_name;
    int index = -1;
};

struct SignalPort
{
    std::vector<std::string> name;
    std::string port_name;
    int width = 0;
    bool output = false;
    uint32_t reg_offset = 0;
};

struct TriggerPort
{
    std::vector<std::string> name;
    std::string port_name;
    int index = -1;
};

struct AXIPort
{
    std::vector<std::string> name;
    std::string port_name;
    AXI::AXI4 axi;
    uint64_t size = 0;
    uint32_t reg_offset = 0;
};

struct ChannelPort
{
    std::vector<std::string> name;
    std::string port_name;
    enum {IN, OUT} dir;
    Yosys::IdString port_valid;
    Yosys::IdString port_ready;
    std::vector<std::string> deps; // relative to path
};

struct EmulationDatabase
{
    std::map<std::vector<std::string>, SysInfo::WireInfo> wire;
    std::map<std::vector<std::string>, SysInfo::RAMInfo> ram;

    std::vector<ClockPort> clock_ports;
    std::vector<SignalPort> signal_ports;
    std::vector<TriggerPort> trigger_ports;
    std::vector<AXIPort> axi_ports;
    std::vector<ChannelPort> channel_ports;

    std::vector<SysInfo::ModelInfo> model;

    std::vector<SysInfo::ScanFFInfo> scan_ff;
    std::vector<SysInfo::ScanRAMInfo> scan_ram;

    void write_sysinfo(std::string file_name);
    void write_loader(std::string file_name);
    void write_checkpoint(std::string ckpt_path);

    EmulationDatabase() {}
};

} // namespace REMU

#endif // #ifndef _DATABASE_H_
