#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "circuit.h"
#include "escape.h"

#include "attr.h"
#include "database.h"
#include "utils.h"

using namespace REMU;

USING_YOSYS_NAMESPACE

std::vector<EmulationDatabase> EmulationDatabase::instances;

void EmulationDatabase::generate_sysinfo()
{
    if (sysinfo_generated)
        return;

    sysinfo.wire = wire;
    sysinfo.ram = ram;

    for (auto &x : clock_ports) {
        sysinfo.clock.push_back({
            .name       = x.name,
            .index      = x.index,
        });
    }

    for (auto &x : signal_ports) {
        sysinfo.signal.push_back({
            .name       = x.name,
            .width      = x.width,
            .output     = x.output,
            .init       = x.init,
            .reg_offset = x.reg_offset,
        });
    }

    for (auto &x : trigger_ports) {
        sysinfo.trigger.push_back({
            .name       = x.name,
            .index      = x.index,
        });
    }

    for (auto &x : axi_ports) {
        sysinfo.axi.push_back({
            .name       = x.name,
            .size       = x.size,
            .reg_offset = x.reg_offset,
        });
    }

    for (auto &x : trace_ports) {
        sysinfo.trace.push_back({
            .name = x.name,
            .type = x.type,
            .port_name = x.port_name,
            .port_width = x.port_width,
            .reg_offset = x.reg_offset,
        });
        log("[DEBUG TRACE] sysinfo_trace_port_name = %s, width = %d\n", x.port_name.c_str(), x.port_width);
    }

    sysinfo.model = model;
    sysinfo.scan_ff = scan_ff;
    sysinfo.scan_ram = scan_ram;

    sysinfo_generated = true;
}

void EmulationDatabase::write_sysinfo(std::string file_name)
{
    std::ofstream f;

    f.open(file_name, std::ios::trunc);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", file_name.c_str());

    generate_sysinfo();

    sysinfo.toJson(f);
    f.close();
}

void EmulationDatabase::write_loader(std::string file_name)
{
    std::ofstream os;

    os.open(file_name, std::ios::trunc);
    if (os.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", file_name.c_str());

    int addr;

    os << "`define LOAD_FF(__LOAD_DATA, EMU_TOP) \\\n";
    addr = 0;
    for (auto &info : scan_ff) {
        if (!info.name.empty()) {
            auto &wire = this->wire.at(info.name);
            os << "    " << flatten_name(info.name);
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

    os << "`define LOAD_MEM(__LOOP_VAR, __LOAD_DATA, EMU_TOP) \\\n";
    addr = 0;
    for (auto &info : scan_ram) {
        auto &ram = this->ram.at(info.name);
        os << "    for (__LOOP_VAR=0; __LOOP_VAR<" << ram.depth << "; __LOOP_VAR=__LOOP_VAR+1) "
           << flatten_name(info.name) << "[__LOOP_VAR+" << ram.start_offset << "] = __LOAD_DATA["
           << addr << "+__LOOP_VAR*" << ram.width << "+:" << ram.width << "]; \\\n";
        addr += ram.width * ram.depth;
    }
    os << "\n";
    os << "`define RAM_BIT_COUNT " << addr << "\n";

    os.close();
}

void EmulationDatabase::write_checkpoint(std::string ckpt_path)
{
    log("Writing initial checkpoint to `%s'\n", ckpt_path.c_str());

    generate_sysinfo();

    CheckpointManager ckpt_mgr(sysinfo, ckpt_path);
    auto ckpt = ckpt_mgr.open(0);

    // Write initial circuit state

    CircuitState circuit(sysinfo);
    circuit.save(ckpt);

    // Write initial signal state & trace

    for (auto &signal : sysinfo.signal) {
        if (signal.output)
            continue;

        auto name = flatten_name(signal.name);
        ckpt_mgr.signal_trace[name][0] = signal.init.empty() ?
            BitVector(signal.width) :
            BitVector(signal.init);
    }

    // ckpt & ckpt_mgr will be flushed on destruction
}

EmulationDatabase& EmulationDatabase::get_instance(Design *design)
{
    const std::string varname = "EMU_DB_IDX";
    int idx = design->scratchpad_get_int(varname, -1);

    if (idx < 0) {
        idx = instances.size();
        instances.emplace_back();
        design->scratchpad_set_int(varname, idx);
    }

    return instances.at(idx);
}
