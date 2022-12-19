#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "escape.h"

#include "attr.h"
#include "database.h"
#include "utils.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

void EmulationDatabase::write_init(std::string init_file) {
    std::ofstream f;

    f.open(init_file.c_str(), std::ios::binary);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", init_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", init_file.c_str());

    for (auto &ff : ff_list) {
        f << ff.init_data.as_string() << "\n";
    }

    for (auto &mem : ram_list) {
        f << mem.init_data.as_string() << "\n";
    }

    f.close();
}

void EmulationDatabase::write_yaml(std::string yaml_file) {
    std::ofstream f;

    f.open(yaml_file.c_str(), std::ios::trunc);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", yaml_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", yaml_file.c_str());

    Config config;

    for (auto &x : ff_list)
        config.ff.push_back(x);

    for (auto &x : ram_list)
        config.ram.push_back(x);

    for (auto &x : user_clocks)
        config.clock.push_back(x);

    for (auto &x : user_resets)
        config.reset.push_back(x);

    for (auto &x : user_trigs)
        config.trig.push_back(x);

    for (auto &x : fifo_ports)
        config.fifo_port.push_back(x);

    for (auto &x : axi_intfs)
        config.axi.push_back(x);

    for (auto &x : models)
        config.model.push_back(x);

    YAML::Node yaml(config);
    f << yaml;
    f.close();
}

void EmulationDatabase::write_loader(std::string loader_file) {
    std::ofstream os;

    os.open(loader_file.c_str(), std::ios::trunc);
    if (os.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", loader_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", loader_file.c_str());

    int addr;

    os << "`define LOAD_FF(__LOAD_DATA, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &ff : ff_list) {
        os << "    __LOAD_DUT";
        for (auto &name : ff.name)
            os << "." << Escape::escape_verilog_id(name);
        if (ff.width != ff.wire_width) {
            if (ff.width == 1)
                os << stringf("[%d]", ff.wire_start_offset + ff.offset);
            else if (ff.wire_upto)
                os << stringf("[%d:%d]", (ff.wire_width - (ff.offset + ff.width - 1) - 1) + ff.wire_start_offset,
                        (ff.wire_width - ff.offset - 1) + ff.wire_start_offset);
            else
                os << stringf("[%d:%d]", ff.wire_start_offset + ff.offset + ff.width - 1,
                        ff.wire_start_offset + ff.offset);
        }
        os << " = __LOAD_DATA[" << addr << "+:" << ff.width << "]; \\\n";
        addr += ff.width;
    }
    os << "\n";
    os << "`define FF_BIT_COUNT " << addr << "\n";

    os << "`define LOAD_MEM(__LOOP_VAR, __LOAD_DATA, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &mem : ram_list) {
        os << "    for (__LOOP_VAR=0; __LOOP_VAR<" << mem.depth << "; __LOOP_VAR=__LOOP_VAR+1) __LOAD_DUT";
        for (auto &name : mem.name)
            os << "." << Escape::escape_verilog_id(name);
        os << "[__LOOP_VAR+" << mem.start_offset << "] = __LOAD_DATA[";
        os << addr << "+__LOOP_VAR*" << mem.width << "+:" << mem.width << "]; \\\n";
        addr += mem.width * mem.depth;
    }
    os << "\n";
    os << "`define RAM_BIT_COUNT " << addr << "\n";

    os.close();
}