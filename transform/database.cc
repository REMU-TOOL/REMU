#include "kernel/yosys.h"
#include "kernel/mem.h"

#include "yaml-cpp/yaml.h"

#include "escape.h"

#include "attr.h"
#include "database.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

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

#if 0
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

void EmulationDatabase::write_init(std::string init_file) {
    std::ofstream f;

    f.open(init_file.c_str(), std::ofstream::binary);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", init_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", init_file.c_str());

    for (auto &src : scanchain_ff) {
        f << const2hex(src.initval) << "\n";
    }

    for (auto &mem : scanchain_ram) {
        for (int i = 0; i < mem.mem_depth; i++) {
            Const word = mem.init_data.extract(i * mem.mem_width, mem.mem_width);
            for (int j = 0; j < mem.mem_width; j += ram_width)
                f << const2hex(word.extract(j, ram_width)) << "\n";
        }
    }

    f.close();
}

void EmulationDatabase::write_yaml(std::string yaml_file) {
    std::ofstream f;

    f.open(yaml_file.c_str(), std::ofstream::trunc);
    if (f.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", yaml_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", yaml_file.c_str());

    YAML::Node root;

    root["ff_width"]  = ff_width;
    root["mem_width"] = ram_width;

    for (auto &src : scanchain_ff) {
        YAML::Node ff_node;
        for (auto &c : src.info) {
            YAML::Node src_node;
            for (auto &s : c.wire_name)
                src_node["name"].push_back(s);
            src_node["offset"] = c.offset;
            src_node["width"] = c.width;
            src_node["is_src"] = c.is_src;
            ff_node.push_back(src_node);
        }
        root["ff"].push_back(ff_node);
    }

    for (auto &mem : scanchain_ram) {
        YAML::Node mem_node;
        for (auto &s : mem.name)
            mem_node["name"].push_back(s);
        mem_node["is_src"] = mem.is_src;
        root["mem"].push_back(mem_node);
    }

    root["circuit"] = ci_root.to_yaml();

#if 0
    for (auto &info : user_clocks) {
        YAML::Node node;
        node["name"] = info.name;
        node["top_name"] = info.top_name;
        root["clock"].push_back(node);
    }

    for (auto &info : user_resets) {
        YAML::Node node;
        node["name"] = info.name;
        node["top_name"] = info.top_name;
        node["index"] = info.index;
        root["reset"].push_back(node);
    }

    for (auto &info : user_trigs) {
        YAML::Node node;
        node["name"] = info.name;
        node["top_name"] = info.top_name;
        node["desc"] = info.desc;
        node["index"] = info.index;
        root["trigger"].push_back(node);
    }

    for (auto &info : fifo_ports) {
        YAML::Node node;
        node["name"] = info.name;
        node["top_name"] = info.top_name;
        node["type"] = info.type;
        node["width"] = info.width;
        node["index"] = info.index;
        root["fifo_port"].push_back(node);
    }

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

    os.open(loader_file.c_str(), std::ofstream::trunc);
    if (os.fail()) {
        log_error("Can't open file `%s' for writing: %s\n", loader_file.c_str(), strerror(errno));
    }

    log("Writing to file `%s'\n", loader_file.c_str());

    int addr;

    os << "`define LOAD_DECLARE integer __load_i;\n";
    os << "`define LOAD_FF_WIDTH " << ff_width << "\n";
    os << "`define LOAD_MEM_WIDTH " << ram_width << "\n";

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

    os.close();
}