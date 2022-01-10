#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

USING_YOSYS_NAMESPACE

const int DATA_WIDTH = 64;
const int TRIG_WIDTH = 32;

const char

    // Usage: specified in emulib stub modules to indicate the component name.
    // Type: string
    // Compatible: module (emulib stubs)
    AttrEmulibComponent     [] = "\\emulib_component",

    // Usage: specified in model implementation to indicate internal signals.
    // Type: string
    // Compatible: wire
    AttrIntfPort            [] = "\\emu_intf_port",

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

bool is_public_id(IdString id);
std::string str_id(IdString id);

template <typename T>
std::vector<std::string> get_hier_name(T *obj) {
    std::vector<std::string> hier;
    if (obj->has_attribute(ID::hdlname))
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
    FfInfo(SigSpec);
    FfInfo(std::string);
    operator std::string();
    FfInfo extract(int offset, int length);
    FfInfo nest(Cell *parent);
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
    MemInfo(Mem &mem, int slices);
    MemInfo nest(Cell *parent);
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

    inline EmulibCellInfo nest(Cell *parent) const {
        EmulibCellInfo res = *this;
        std::vector<std::string> hier = get_hier_name(parent);
        res.name.insert(res.name.begin(), hier.begin(), hier.end());
        return res;
    }
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
