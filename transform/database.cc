#include "kernel/yosys.h"
#include "kernel/mem.h"

#include "yaml-cpp/yaml.h"

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

PRIVATE_NAMESPACE_END

FfInfo FfMemInfoExtractor::ff(const SigSpec &sig, const Const &initval) {
    FfInfo res;
    for (auto &chunk : sig.chunks()) {
        log_assert(chunk.is_wire());
        FfInfoChunk chunkinfo; 
        chunkinfo.wire_name = design.hier_name_of(chunk.wire, target);
        chunkinfo.wire_width = chunk.wire->width;
        chunkinfo.wire_start_offset = chunk.wire->start_offset;
        chunkinfo.wire_upto = chunk.wire->upto;
        chunkinfo.width = chunk.width;
        chunkinfo.offset = chunk.offset;
        chunkinfo.is_src = chunk.wire->has_attribute(ID::src);
        chunkinfo.is_model = design.check_hier_attr(Attr::ModelImp, chunk.wire);
        res.info.push_back(chunkinfo);
    }
    res.initval = initval;
    return res;
}

MemInfo FfMemInfoExtractor::mem(const Mem &mem, int slices) {
    MemInfo res;
    res.name = design.hier_name_of(mem.module, target) + "." + design.name_of(mem.memid);
    res.depth = mem.size * slices;
    res.slices = slices;
    res.mem_width = mem.width;
    res.mem_depth = mem.size;
    res.mem_start_offset = mem.start_offset;
    res.is_src = mem.has_attribute(ID::src);
    res.is_model = design.check_hier_attr(Attr::ModelImp, &mem);
    res.init_data = mem.get_init_data();
    return res;
}

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

    YAML::Node node;

    node["ff_width"]  = ff_width;
    node["mem_width"] = ram_width;

    node["ff"] = YAML::Node(YAML::NodeType::Sequence);
    for (auto &src : scanchain_ff) {
        YAML::Node ff_node;
        for (auto &c : src.info) {
            YAML::Node src_node;
            src_node["name"] = c.wire_name;
            src_node["offset"] = c.offset;
            src_node["width"] = c.width;
            src_node["is_src"] = c.is_src;
            ff_node.push_back(src_node);
        }
        node["ff"].push_back(ff_node);
    }

    node["mem"] = YAML::Node(YAML::NodeType::Sequence);
    for (auto &mem : scanchain_ram) {
        YAML::Node mem_node;
        mem_node["name"] = mem.name;
        mem_node["width"] = mem.mem_width;
        mem_node["depth"] = mem.mem_depth;
        mem_node["start_offset"] = mem.mem_start_offset;
        mem_node["is_src"] = mem.is_src;
        node["mem"].push_back(mem_node);
    }

    f << node;
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

    os << "`define LOAD_FF(__LOAD_FF_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &src : scanchain_ff) {
        int offset = 0;
        for (auto chunk : src.info) {
            if (!chunk.is_src)
                continue;
            os  << "    __LOAD_DUT." << chunk.wire_name;
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
            os  << " = __LOAD_FF_DATA[__LOAD_OFFSET+" << addr << "]"
                << "[" << chunk.width + offset - 1 << ":" << offset << "]; \\\n";
            offset += chunk.width;
        }
        addr++;
    }
    os << "\n";
    os << "`define CHAIN_FF_WORDS " << addr << "\n";

    os << "`define LOAD_MEM(__LOAD_MEM_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
    addr = 0;
    for (auto &mem : scanchain_ram) {
        if (!mem.is_src)
            continue;
        os  << "    for (__load_i=0; __load_i<" << mem.mem_depth << "; __load_i=__load_i+1) __LOAD_DUT."
            << mem.name << "[__load_i+" << mem.mem_start_offset << "] = {";
        for (int i = mem.slices - 1; i >= 0; i--)
            os << "__LOAD_MEM_DATA[__LOAD_OFFSET+__load_i*" << mem.slices << "+" << addr + i << "]" << (i != 0 ? ", " : "");
        os << "}; \\\n";
        addr += mem.depth;
    }
    os << "\n";
    os << "`define CHAIN_MEM_WORDS " << addr << "\n";

    os.close();
}