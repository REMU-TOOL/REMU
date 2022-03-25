#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

USING_YOSYS_NAMESPACE

const int TRIG_WIDTH = 32;

const char

    // Usage: specified in model implementation to indicate internal signals.
    // Type: string
    // Compatible: wire
    AttrIntfPort            [] = "\\emu_intf_port",

    // Usage: specified by emu_rewrite_clock to indicate rewritten cells.
    // Type: bool
    // Compatible: cell
    AttrClkRewritten    [] = "\\emu_clk_rewritten";

bool is_public_id(IdString id);
std::string str_id(IdString id);

std::string verilog_id(const std::string &name);
std::string verilog_hier_name(const std::vector<std::string> &hier);
std::string simple_hier_name(const std::vector<std::string> &hier);

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
    FfInfo(SigSpec sig, std::vector<std::string> path = {});
    FfInfo(std::string, std::vector<std::string> path = {});
    operator std::string();
    FfInfo extract(int offset, int length);
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
    MemInfo(Mem &mem, int slices, std::vector<std::string> path = {});
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
};

typedef std::map<std::string, std::vector<EmulibCellInfo>> EmulibData;

struct Database {
    IdString top;
    dict<IdString, ScanChainData> scanchain;
    dict<IdString, EmulibData> emulib;

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
SigSpec measure_clk(Module *module, SigSpec clk, SigSpec gated_clk);

} // namespace Emu

#endif // #ifndef _EMU_H_
