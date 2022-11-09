#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "escape.h"

#include "attr.h"
#include "database.h"
#include "utils.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

#if 0
PRIVATE_NAMESPACE_BEGIN

std::string const2hex(const Const &val) {
    int len = (GetSize(val) + 3) / 4;
    std::string res;
    res.resize(len, ' ');

    for (int i = 0; i < len; i++) {
        int digit = val.extract(i*4, 4).as_int();
        char c;
        if (digit >= 10)
            c = 'a' + digit - 10;
        else
            c = '0' + digit;
        res[len-1-i] = c;
    }

    return res;
}

std::string hier2flat(const std::vector<std::string> &hier) {
    std::ostringstream ss;
    bool is_first = true;
    for (auto & s : hier) {
        if (is_first)
            is_first = false;
        else
            ss << ".";
        ss << Escape::escape_verilog_id(s);
    }
    return ss.str();
}

PRIVATE_NAMESPACE_END

void FfMemInfoExtractor::add_ff(const SigSpec &sig, const Const &initval) {
    FfInfo res;
    for (auto &chunk : sig.chunks()) {
        log_assert(chunk.is_wire());
        std::vector<std::string> path = design.hier_name_of(chunk.wire, target);

        FfInfoChunk chunkinfo;
        chunkinfo.wire_name = path;
        chunkinfo.wire_width = chunk.wire->width;
        chunkinfo.wire_start_offset = chunk.wire->start_offset;
        chunkinfo.wire_upto = chunk.wire->upto;
        chunkinfo.width = chunk.width;
        chunkinfo.offset = chunk.offset;
        chunkinfo.is_src = chunk.wire->has_attribute(ID::src);
        res.info.push_back(chunkinfo);

        database.ci_root.add(path, CircuitInfo::Wire(
            chunk.wire->width,
            chunk.wire->start_offset,
            chunk.wire->upto
        ));
    }
    res.initval = initval;
    database.scanchain_ff.push_back(res);
}

void FfMemInfoExtractor::add_mem(const Mem &mem, int slices) {
    std::vector<std::string> path = design.hier_name_of(mem.memid, mem.module, target);

    MemInfo res;
    res.name = path;
    res.depth = mem.size * slices;
    res.slices = slices;
    res.mem_width = mem.width;
    res.mem_depth = mem.size;
    res.mem_start_offset = mem.start_offset;
    res.is_src = mem.has_attribute(ID::src);
    res.init_data = mem.get_init_data();
    database.scanchain_ram.push_back(res);

    database.ci_root.add(path, CircuitInfo::Mem(
        mem.width,
        mem.size,
        mem.start_offset
    ));
}
#endif

EmulationDatabase::EmulationDatabase(Design *design)
{
    design_info.top = pretty_name(design->top_module()->name);
    for (Module *module : design->modules()) {
        ModuleInfo module_info;
        for (Cell *cell : module->cells()) {
            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                FfData ff(nullptr, cell);
                for (auto &chunk : ff.sig_q.chunks()) {
                    log_assert(chunk.is_wire());
                    Wire *wire = chunk.wire;
                    std::string name = pretty_name(wire->name);
                    if (module_info.cells.count(name))
                        continue;
                    RegInfo reg;
                    reg.width = wire->width;
                    reg.start_offset = wire->start_offset;
                    reg.upto = wire->upto;
                    module_info.cells.emplace(
                        std::piecewise_construct,
                        std::forward_as_tuple(name),
                        std::forward_as_tuple(std::move(reg)));
                }
            }
            else if (design->has(cell->type)) {
                std::string name = pretty_name(cell->name);
                std::string module_name = pretty_name(cell->type);
                module_info.cells.emplace(
                    std::piecewise_construct,
                    std::forward_as_tuple(name),
                    std::forward_as_tuple(module_name));
            }
        }
        for (auto &mem : Mem::get_all_memories(module)) {
            std::string name = pretty_name(mem.memid);
            RegArrayInfo array;
            array.width = mem.width;
            array.depth = mem.size;
            array.start_offset = mem.start_offset;
            array.dissolved = false;
            module_info.cells.emplace(
                std::piecewise_construct,
                std::forward_as_tuple(name),
                std::forward_as_tuple(std::move(array)));
        }
        std::string name = pretty_name(module->name);
        design_info.modules.emplace(
            std::piecewise_construct,
            std::forward_as_tuple(name),
            std::forward_as_tuple(std::move(module_info)));
    }
}

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

    YAML::Node root;

    root["design"] = design_info;
    root["ff"] = ff_list;
    root["ram"] = ram_list;
    root["clock"] = user_clocks;
    root["reset"] = user_resets;
    root["trigger"] = user_trigs;
    root["fifo_port"] = fifo_ports;
    root["channels"] = channels;

#if 0
    for (auto &info : model_mods) {
        YAML::Node node;
        node["name"] = info.name;
        node["module_name"] = info.module_name;
        root["model_mods"].push_back(node);
    }
#endif

    f << root;
    f.close();
}

void EmulationDatabase::write_loader(std::string loader_file) {
    std::ofstream os;

    os.open(loader_file.c_str(), std::ios::trunc);
    if (os.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", loader_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", loader_file.c_str());

#if 0

    int addr;

    os << "`define LOAD_DECLARE integer __load_i;\n";
    os << "`define LOAD_FF(__LOAD_DATA_FUNC, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &src : scanchain_ff) {
        int offset = 0;
        for (auto chunk : src.info) {
            if (!chunk.is_src)
                continue;
            os  << "    __LOAD_DUT." << hier2flat(chunk.wire_name);
            if (chunk.width != chunk.wire_width) {
                if (chunk.width == 1)
                    os << stringf("[%d]", chunk.wire_start_offset + chunk.offset);
                else if (chunk.wire_upto)
                    os << stringf("[%d:%d]", (chunk.wire_width - (chunk.offset + chunk.width - 1) - 1) + chunk.wire_start_offset,
                            (chunk.wire_width - chunk.offset - 1) + chunk.wire_start_offset);
                else
                    os << stringf("[%d:%d]", chunk.wire_start_offset + chunk.offset + chunk.width - 1,
                            chunk.wire_start_offset + chunk.offset);
            }
            os  << " = __LOAD_DATA_FUNC(" << addr << ")"
                << " >> " << offset << "; \\\n";
            offset += chunk.width;
        }
        addr++;
    }
    os << "\n";
    os << "`define CHAIN_FF_WORDS " << addr << "\n";

    os << "`define LOAD_MEM(__LOAD_DATA_FUNC, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &mem : scanchain_ram) {
        if (!mem.is_src)
            continue;
        os  << "    for (__load_i=0; __load_i<" << mem.mem_depth << "; __load_i=__load_i+1) __LOAD_DUT."
            << hier2flat(mem.name) << "[__load_i+" << mem.mem_start_offset << "] = {";
        for (int i = mem.slices - 1; i >= 0; i--)
            os << "__LOAD_DATA_FUNC(__load_i*" << mem.slices << "+" << addr + i << ")" << (i != 0 ? ", " : "");
        os << "}; \\\n";
        addr += mem.depth;
    }
    os << "\n";
    os << "`define CHAIN_MEM_WORDS " << addr << "\n";
#endif

    os.close();
}