#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "escape.h"

#include "attr.h"
#include "database.h"
#include "utils.h"

using namespace REMU;

USING_YOSYS_NAMESPACE

void EmulationDatabase::write_sysinfo(std::string file_name) {
    std::ofstream f;

    f.open(file_name, std::ios::trunc);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", file_name.c_str());

    // Copy & prepend EMU_TOP to all records

    auto emu_top = "EMU_TOP";

    SysInfo sysinfo;

    for (auto &x : wire) {
        auto name = x.first;
        name.insert(name.begin(), emu_top);
        sysinfo.wire[name] = x.second;
    }

    for (auto &x : ram) {
        auto name = x.first;
        name.insert(name.begin(), emu_top);
        sysinfo.ram[name] = x.second;
    }

    for (auto &x : clock_ports) {
        auto name = x.name;
        name.insert(name.begin(), emu_top);
        sysinfo.clock.push_back({
            .name       = name,
            .index      = x.index,
        });
    }

    for (auto &x : signal_ports) {
        auto name = x.name;
        name.insert(name.begin(), emu_top);
        sysinfo.signal.push_back({
            .name       = name,
            .width      = x.width,
            .output     = x.output,
            .reg_offset = x.reg_offset,
        });
    }

    for (auto &x : trigger_ports) {
        auto name = x.name;
        name.insert(name.begin(), emu_top);
        sysinfo.trigger.push_back({
            .name       = name,
            .index      = x.index,
        });
    }

    for (auto &x : axi_ports) {
        auto name = x.name;
        name.insert(name.begin(), emu_top);
        sysinfo.axi.push_back({
            .name       = name,
            .size       = x.size,
            .reg_offset = x.reg_offset,
        });
    }

    for (auto x : model) {
        x.name.insert(x.name.begin(), emu_top);
        sysinfo.model.push_back(x);
    }

    for (auto x : scan_ff) {
        if (!x.name.empty())
            x.name.insert(x.name.begin(), emu_top);
        sysinfo.scan_ff.push_back(x);
    }

    for (auto x : scan_ram) {
        if (!x.name.empty())
            x.name.insert(x.name.begin(), emu_top);
        sysinfo.scan_ram.push_back(x);
    }

    f << sysinfo;
    f.close();
}

void EmulationDatabase::write_loader(std::string file_name) {
    std::ofstream os;

    os.open(file_name, std::ios::trunc);
    if (os.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", file_name.c_str());

    int addr;

    os << "`define LOAD_FF(__LOAD_DATA, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &info : scan_ff) {
        if (!info.name.empty()) {
            auto &wire = this->wire.at(info.name);
            os << "    __LOAD_DUT";
            for (auto &name : info.name)
                os << "." << Escape::escape_verilog_id(name);
            if (info.width != wire.width) {
                if (info.width == 1)
                    os << stringf("[%d]", wire.start_offset + info.offset);
                else if (wire.upto)
                    os << stringf("[%d:%d]", (wire.width - (info.offset + info.width - 1) - 1) + wire.start_offset,
                            (wire.width - info.offset - 1) + wire.start_offset);
                else
                    os << stringf("[%d:%d]", wire.start_offset + info.offset + info.width - 1,
                            wire.start_offset + info.offset);
            }
            os << " = __LOAD_DATA[" << addr << "+:" << info.width << "]; \\\n";
        }
        addr += info.width;
    }
    os << "\n";
    os << "`define FF_BIT_COUNT " << addr << "\n";

    os << "`define LOAD_MEM(__LOOP_VAR, __LOAD_DATA, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &info : scan_ram) {
        auto &ram = this->ram.at(info.name);
        os << "    for (__LOOP_VAR=0; __LOOP_VAR<" << ram.depth << "; __LOOP_VAR=__LOOP_VAR+1) __LOAD_DUT";
        for (auto &name : info.name)
            os << "." << Escape::escape_verilog_id(name);
        os << "[__LOOP_VAR+" << ram.start_offset << "] = __LOAD_DATA[";
        os << addr << "+__LOOP_VAR*" << ram.width << "+:" << ram.width << "]; \\\n";
        addr += ram.width * ram.depth;
    }
    os << "\n";
    os << "`define RAM_BIT_COUNT " << addr << "\n";

    os.close();
}