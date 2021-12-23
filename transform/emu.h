#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

const int DATA_WIDTH = 64;
const int TRIG_WIDTH = 32;

const char
    PortClk         [] = "\\EMU_CLK",
    PortFfScanEn    [] = "\\EMU_FF_SE",
    PortFfDataIn    [] = "\\EMU_FF_DI",
    PortFfDataOut   [] = "\\EMU_FF_DO",
    PortRamScanEn   [] = "\\EMU_RAM_SE",
    PortRamScanDir  [] = "\\EMU_RAM_SD",
    PortRamDataIn   [] = "\\EMU_RAM_DI",
    PortRamDataOut  [] = "\\EMU_RAM_DO",
    PortRamLastIn   [] = "\\EMU_RAM_LI",
    PortRamLastOut  [] = "\\EMU_RAM_LO",
    PortDutFfClk    [] = "\\EMU_DUT_FF_CLK",
    PortDutRamClk   [] = "\\EMU_DUT_RAM_CLK",
    PortDutRst      [] = "\\EMU_DUT_RST",
    PortDutTrig     [] = "\\EMU_DUT_TRIG",
    PortPCValid     [] = "\\EMU_PC_VALID",
    PortPCData      [] = "\\EMU_PC_DATA";

const char

    // Usage: specified in emulib stub modules to indicate the component name.
    // Type: string
    // Compatible: module (emulib stubs)
    AttrEmulibComponent     [] = "\\emulib_component",

    // Usage: specified in model implementation to indicate internal signals.
    // Type: string
    // Compatible: wire
    AttrInternalSig         [] = "\\emu_internal_sig",

    // Usage: specified in model implementation to avoid scan chain insertion.
    // Type: bool
    // Compatible: cell, wire
    AttrNoScanchain         [] = "\\emu_no_scanchain",

    // Usage: specified by emu_process_lib to indicate cells & wires loaded from model implementation.
    // Type: bool
    // Compatible: cell, wire
    AttrModel               [] = "\\emu_model",

    // Usage: specified by emu_instrument to indicate completion of the pass.
    // Type: bool
    // Compatible: module
    AttrInstrumented        [] = "\\emu_instrumented",

    // Usage: specified by emu_process_lib to indicate completion of the pass.
    // Type: bool
    // Compatible: module
    AttrLibProcessed        [] = "\\emu_lib_processed",

    // Usage: specified by emu_process_lib to indicate rewritten clock ports.
    // Type: bool
    // Compatible: wire (clock ports)
    AttrClkPortRewritten    [] = "\\emu_clk_port_rewritten";

// fixup_ports must be called after all ports are created
Yosys::Wire *emu_create_port(Yosys::Module *module, Yosys::IdString name, int width, bool output);
Yosys::Wire *emu_get_port(Yosys::Module *module, Yosys::IdString name);
Yosys::IdString emu_get_port_id(Yosys::Module *module, Yosys::IdString name);

bool is_public_id(Yosys::IdString id);
std::string str_id(Yosys::IdString id);

template <typename T>
std::vector<std::string> get_hier_name(T *obj) {
    std::vector<std::string> hier;
    if (obj->has_attribute(Yosys::ID::hdlname))
        hier = obj->get_hdlname_attribute();
    else
        hier.push_back(str_id(obj->name));
    return hier;
}

std::string verilog_id(const std::string &name);
std::string verilog_hier_name(const std::vector<std::string> &hier);

struct FfInfoChunk {
    std::vector<std::string> name;
    bool is_public;
    int offset;
    int width;
    FfInfoChunk() {}
    FfInfoChunk extract(int offset, int length) {
        FfInfoChunk res = *this;
        res.offset += offset;
        res.width = length;
        return res;
    }
};

struct FfInfo {
    std::vector<FfInfoChunk> info;
    FfInfo() {}
    FfInfo(Yosys::SigSpec);
    FfInfo(std::string);
    operator std::string();
    FfInfo extract(int offset, int length);
    FfInfo nest(Yosys::Cell *parent);
};

struct MemInfo {
    std::vector<std::string> name;
    bool is_public;
    int depth;
    int slices;
    int mem_width;
    int mem_depth;
    int mem_start_offset;
    MemInfo() {}
    MemInfo(Yosys::Mem &mem, int slices);
    MemInfo nest(Yosys::Cell *parent);
};

struct ScanChainData {
    std::vector<FfInfo> ff;
    std::vector<MemInfo> mem;
    ScanChainData() {}
    ScanChainData(std::vector<FfInfo> &ff, std::vector<MemInfo> &mem) : ff(ff), mem(mem) {}
    inline int mem_sc_depth() const {
        int res = 0;
        for (auto &m : mem)
            res += m.slices;
        return res;
    }
};

struct EmulibCellInfo {
    std::vector<std::string> name;
    std::map<std::string, int> attrs;

    inline EmulibCellInfo nest(Yosys::Cell *parent) const {
        EmulibCellInfo res = *this;
        std::vector<std::string> hier = get_hier_name(parent);
        res.name.insert(res.name.begin(), hier.begin(), hier.end());
        return res;
    }
};

typedef std::map<std::string, std::vector<EmulibCellInfo>> EmulibData;

struct Database {
    ScanChainData scanchain;
    EmulibData emulib;

    static std::map<std::string, Database> databases;
};

class JsonWriter {
    std::ostream &os;
    std::vector<std::pair<char, bool>> stack;
    bool after_key;

    inline void indent() {
        os << std::string(stack.size(), '\t');
    }

    inline void comma_and_newline() {
        if (!stack.back().second) {
            stack.back().second = true;
        }
        else {
            os << ",\n";
        }
    }

    inline void value_preoutput() {
        if (!after_key) {
            comma_and_newline();
            indent();
        }
    }

public:

    JsonWriter &key(const std::string &key);
    JsonWriter &string(const std::string &str);

    template <typename T> inline JsonWriter &value(const T &value) {
        value_preoutput();
        os << value;
        after_key = false;
        return *this;
    }

    JsonWriter &enter_array();
    JsonWriter &enter_object();
    JsonWriter &back();
    void end();

    JsonWriter(std::ostream &os);
    ~JsonWriter();
};

// Measure a gated clock with its source clock
// Returns a signal with 1-cycle delay to its enable signal
Yosys::SigSpec measure_clk(Yosys::Module *module, Yosys::SigSpec clk, Yosys::SigSpec gated_clk);

} // namespace Emu

#endif // #ifndef _EMU_H_
