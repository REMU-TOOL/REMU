#include "emu.h"
#include <cctype>

USING_YOSYS_NAMESPACE

namespace Emu {

std::map<std::string, Database> Database::databases;

bool is_public_id(IdString id) {
    return id[0] == '\\';
}

std::string str_id(IdString id) {
    if (is_public_id(id))
        return id.str().substr(1);
    else
        return id.str();
}

std::string verilog_id(const std::string &name) {
    const pool<std::string> keywords = {
        "accept_on", "alias", "always", "always_comb", "always_ff", "always_latch", "and", 
        "assert", "assign", "assume", "automatic", "before", "begin", "bind", "bins", "binsof", 
        "bit", "break", "buf", "bufif0", "bufif1", "byte", "case", "casex", "casez", "cell", 
        "chandle", "checker", "class", "clocking", "cmos", "config", "const", "constraint", 
        "context", "continue", "cover", "covergroup", "coverpoint", "cross", "deassign", 
        "default", "defparam", "design", "disable", "dist", "do", "edge", "else", "end", 
        "endcase", "endchecker", "endclass", "endclocking", "endconfig", "endfunction", "endgenerate", 
        "endgroup", "endinterface", "endmodule", "endpackage", "endprimitive", "endprogram", 
        "endproperty", "endspecify", "endsequence", "endtable", "endtask", "enum", "event", 
        "eventually", "expect", "export", "extends", "extern", "final", "first_match", "for", 
        "force", "foreach", "forever", "fork", "forkjoin", "function", "generate", "genvar", 
        "global", "highz0", "highz1", "if", "iff", "ifnone", "ignore_bins", "illegal_bins", 
        "implements", "implies", "import", "incdir", "include", "initial", "inout", "input", 
        "inside", "instance", "int", "integer", "interconnect", "interface", "intersect", 
        "join", "join_any", "join_none", "large", "let", "liblist", "library", "local", "localparam", 
        "logic", "longint", "macromodule", "matches", "medium", "modport", "module", "nand", 
        "negedge", "nettype", "new", "nexttime", "nmos", "nor", "noshowcancelled", "not", 
        "notif0", "notif1", "null", "or", "output", "package", "packed", "parameter", "pmos", 
        "posedge", "primitive", "priority", "program", "property", "protected", "pull0", 
        "pull1", "pulldown", "pullup", "pulsestyle_ondetect", "pulsestyle_onevent", "pure", 
        "rand", "randc", "randcase", "randsequence", "rcmos", "real", "realtime", "ref", 
        "reg", "reject_on", "release", "repeat", "restrict", "return", "rnmos", "rpmos", 
        "rtran", "rtranif0", "rtranif1", "s_always", "s_eventually", "s_nexttime", "s_until", 
        "s_until_with", "scalared", "sequence", "shortint", "shortreal", "showcancelled", 
        "signed", "small", "soft", "solve", "specify", "specparam", "static", "string", "strong", 
        "strong0", "strong1", "struct", "super", "supply0", "supply1", "sync_accept_on", 
        "sync_reject_on", "table", "tagged", "task", "this", "throughout", "time", "timeprecision", 
        "timeunit", "tran", "tranif0", "tranif1", "tri", "tri0", "tri1", "triand", "trior", 
        "trireg", "type", "typedef", "union", "unique", "unique0", "unsigned", "until", "until_with", 
        "untyped", "use", "uwire", "var", "vectored", "virtual", "void", "wait", "wait_order", 
        "wand", "weak", "weak0", "weak1", "while", "wildcard", "wire", "with", "within", 
        "wor", "xnor", "xor"
    };

    if (name.empty())
        goto escape;

    if (!isalpha(name[0]) && name[0] != '_')
        goto escape;

    for (size_t i = 1; i < name.size(); i++) {
        char c = name[i];
        if (!isalnum(c) && c != '_' && c != '$')
            goto escape;
    }

    if (keywords.count(name) != 0)
        goto escape;

    return name;

escape:
    return "\\" + name + " ";
}

std::string verilog_hier_name(const std::vector<std::string> &hier) {
    std::ostringstream os;
    bool first = true;
    for (auto &name : hier) {
        if (first)
            first = false;
        else
            os << ".";
        os << verilog_id(name);
    }
    return os.str();
}

// FIXME: Use verilog_hier_name
// This is a workaround to handle hierarchical names in genblks as yosys can only generate
// such information in escaped ids. This breaks the support of escaped ids in user design.
std::string simple_hier_name(const std::vector<std::string> &hier) {
    std::ostringstream os;
    bool first = true;
    for (auto &name : hier) {
        if (first)
            first = false;
        else
            os << ".";
        os << name;
    }
    return os.str();
}

FfInfo::FfInfo(SigSpec sig, std::vector<std::string> path) {
    for (auto &c : sig.chunks())
        if (c.is_wire()) {
            FfInfoChunk chunk;
            chunk.name = path;
            chunk.name.push_back(str_id(c.wire->name));
            chunk.is_public = is_public_id(c.wire->name);
            chunk.offset = c.offset;
            chunk.width = c.width;
            info.push_back(chunk);
        }
}

FfInfo::FfInfo(std::string str, std::vector<std::string> path) {
    std::istringstream s(str);
    FfInfoChunk chunk;
    int name_size;
    while (s >> name_size) {
        chunk.name = path;
        while (name_size--) {
            std::string n;
            s >> n;
            chunk.name.push_back(n);
        }
        s >> chunk.is_public;
        s >> chunk.offset;
        s >> chunk.width;
        info.push_back(chunk);
    }
}

FfInfo::operator std::string() {
    std::ostringstream s;
    bool first = true;
    for (auto &c : info) {
        if (c.name.empty())
            continue;
        if (first)
            first = false;
        else
            s << " ";
        s << c.name.size() << " ";
        for (auto &n : c.name)
            s << n << " ";
        s << c.is_public << " " << c.offset << " " << c.width;
    }
    return s.str();
}

FfInfo FfInfo::extract(int offset, int length) {
    FfInfo res;
    auto it = info.begin();
    int chunkoff = 0, chunklen = 0;
    while (offset > 0) {
        if (it->width > offset) {
            chunkoff = offset;
            offset = 0;
        }
        else {
            offset -= it->width;
            ++it;
        }
    }
    while (length > 0) {
        if (it->width > length) {
            chunklen = length;
            length = 0;
        }
        else {
            chunklen = it->width;
            length -= chunklen;
        }
        res.info.push_back(it->extract(chunkoff, chunklen));
        chunkoff = 0;
        ++it;
    }
    return res;
}

MemInfo::MemInfo(Mem &mem, int slices, std::vector<std::string> path) {
    name = path;
    name.push_back(str_id(mem.cell->name));
    is_public = is_public_id(mem.cell->name);
    this->depth = mem.size * slices;
    this->slices = slices;
    mem_width = mem.width;
    mem_depth = mem.size;
    mem_start_offset = mem.start_offset;
}

JsonWriter &JsonWriter::key(const std::string &key) {
    comma_and_newline();
    indent();
    os << "\"" << key << "\": ";
    after_key = true;
    return *this;
}

JsonWriter &JsonWriter::string(const std::string &str) {
    value_preoutput();
    os << "\"";
    for (char c : str) {
        switch (c) {
            case '"':   os << "\\\"";   break;
            case '\\':  os << "\\\\";   break;
            default:    os << c;        break;
        }
    }
    os << "\"";
    after_key = false;
    return *this;
}

JsonWriter &JsonWriter::enter_array() {
    value_preoutput();
    os << "[\n";
    stack.push_back({']', false});
    after_key = false;
    return *this;
}

JsonWriter &JsonWriter::enter_object() {
    value_preoutput();
    os << "{\n";
    stack.push_back({'}', false});
    after_key = false;
    return *this;
}

JsonWriter &JsonWriter::back() {
    char c = stack.back().first;
    stack.pop_back();
    os << "\n";
    indent();
    os << c;
    after_key = false;
    return *this;
}

void JsonWriter::end() {
    while (stack.size() > 0)
        back();
}

JsonWriter::JsonWriter(std::ostream &os): os(os), after_key(false) {
    os << "{\n";
    stack.push_back({'}', false});
}

JsonWriter::~JsonWriter() {
    end();
}

SigSpec measure_clk(Module *module, SigSpec clk, SigSpec gated_clk) {
    Wire *a = module->addWire(NEW_ID);
    Wire *b = module->addWire(NEW_ID);
    a->attributes[ID::init] = Const(0, 1);
    b->attributes[ID::init] = Const(1, 1);
    module->addDff(NEW_ID, clk, b, a); // reg a
    module->addDff(NEW_ID, gated_clk, module->Not(NEW_ID, b), b); // reg b
    return module->Xor(NEW_ID, a, b);
}

} // namespace EmuUtil
