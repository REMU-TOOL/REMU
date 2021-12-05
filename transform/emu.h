#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

const int DATA_WIDTH = 64;
const int TRIG_WIDTH = 32;

const char
    PortClk         [] = "\\$EMU$CLK",
    PortFfScanEn    [] = "\\$EMU$FF$SE",
    PortFfDataIn    [] = "\\$EMU$FF$DI",
    PortFfDataOut   [] = "\\$EMU$FF$DO",
    PortRamScanEn   [] = "\\$EMU$RAM$SE",
    PortRamScanDir  [] = "\\$EMU$RAM$SD",
    PortRamDataIn   [] = "\\$EMU$RAM$DI",
    PortRamDataOut  [] = "\\$EMU$RAM$DO",
    PortRamLastIn   [] = "\\$EMU$RAM$LI",
    PortRamLastOut  [] = "\\$EMU$RAM$LO",
    PortDutFfClk    [] = "\\$EMU$DUT$FF$CLK",
    PortDutRamClk   [] = "\\$EMU$DUT$RAM$CLK",
    PortDutRst      [] = "\\$EMU$DUT$RST",
    PortDutTrig     [] = "\\$EMU$DUT$TRIG";

const char
    AttrNoScanchain         [] = "\\emu_no_scanchain",
    AttrInstrumented        [] = "\\emu_instrumented",
    AttrLibProcessed        [] = "\\emu_lib_processed",
    AttrClkPortRewritten    [] = "\\emu_clk_port_rewritten";

template <typename T>
inline void unused(T &var) { (void)var; }

bool is_public_id(Yosys::IdString id);
std::string str_id(Yosys::IdString id);

typedef std::vector<std::string> HierName;

template <typename T>
HierName get_hier_name(T *obj) {
    HierName hier;
    if (obj->has_attribute(Yosys::ID::hdlname))
        hier = obj->get_hdlname_attribute();
    else
        hier.push_back(str_id(obj->name));
    return hier;
}

std::string verilog_id(const std::string &name);
std::string verilog_hier_name(const HierName &hier);

struct FfInfoChunk {
    HierName name;
    bool is_public;
    int offset;
    int width;
    FfInfoChunk() {}
    FfInfoChunk(HierName name, bool is_public, int offset, int width)
        : name(name), is_public(is_public), offset(offset), width(width) {}
    FfInfoChunk extract(int offset, int length) {
        return FfInfoChunk(name, is_public, this->offset + offset, length);
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
    HierName name;
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

struct DutClkInfo {
    HierName name;
    int cycle_ps;
    int phase_ps;
};

struct DutRstInfo {
    HierName name;
    int duration_ns;
};

struct DutTrigInfo {
    HierName name;
};

struct EmulibData {
    std::vector<DutClkInfo> clk;
    std::vector<DutRstInfo> rst;
    std::vector<DutTrigInfo> trig;
    EmulibData nest(Yosys::Cell *parent);
};

struct Database {
    Yosys::dict<Yosys::IdString, ScanChainData> scanchain; // per-module
    Yosys::dict<Yosys::IdString, EmulibData> emulib; // per-module
    std::string top_name;

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
