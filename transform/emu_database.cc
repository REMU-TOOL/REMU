#include "kernel/yosys.h"

#include "yaml-cpp/yaml.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuDatabaseWorker {
    virtual void operator()(std::string db_name, std::ostream &os) = 0;
};

struct WriteConfigWorker : public EmuDatabaseWorker {
    void operator()(std::string db_name, std::ostream &os) override {
        Database &database = Database::databases.at(db_name);

        if (database.top.empty()) {
            log_warning("Database %s is incomplete and ignored\n", db_name.c_str());
            return;
        }

        EmulibData &emulib = database.emulib.at(database.top);
        ScanChainData &scanchain = database.scanchain.at(database.top);
        JsonWriter json(os);

        json.key("width").value(DATA_WIDTH);

        int ff_addr = 0;
        json.key("ff").enter_array();
        for (auto &src : scanchain.ff) {
            json.enter_object();
            json.key("addr").value(ff_addr);
            json.key("src").enter_array();
            int new_off = 0;
            for (auto &c : src.info) {
                json.enter_object();
                json.key("name").enter_array();
                for (auto &s : c.name)
                    json.string(s);
                json.back();
                json.key("is_public").value(c.is_public);
                json.key("offset").value(c.offset);
                json.key("width").value(c.width);
                json.key("new_offset").value(new_off);
                json.back();
                new_off += c.width;
            }
            json.back();
            json.back();
            ff_addr++;
        }
        json.back();
        json.key("ff_size").value(ff_addr);

        int mem_addr = 0;
        json.key("mem").enter_array();
        for (auto &mem : scanchain.mem) {
            json.enter_object();
            json.key("addr").value(mem_addr);
            json.key("name").enter_array();
            for (auto &s : mem.name)
                json.string(s);
            json.back();
            json.key("is_public").value(mem.is_public);
            json.key("width").value(mem.mem_width);
            json.key("depth").value(mem.mem_depth);
            json.key("start_offset").value(mem.mem_start_offset);
            json.back();
            mem_addr += mem.depth;
        }
        json.back();
        json.key("mem_size").value(mem_addr);

        for (auto &section : emulib) {
            int addr = 0;
            json.key(section.first).enter_array();
            for (auto &info : section.second) {
                json.enter_object();
                json.key("addr").value(addr);
                json.key("name").enter_array();
                for (auto &s : info.name)
                    json.string(s);
                json.back();
                for (auto &attr : info.attrs) {
                    json.key(attr.first).value(attr.second);
                }
                json.back();
                addr++;
            }
            json.back();
        }

        json.end();
    }
} WriteConfigWorker;

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

struct WriteYAMLWorker : public EmuDatabaseWorker {
    void operator()(std::string db_name, std::ostream &os) override {
        Database &database = Database::databases.at(db_name);

        if (database.top.empty()) {
            log_warning("Database %s is incomplete and ignored\n", db_name.c_str());
            return;
        }

        EmulibData &emulib = database.emulib.at(database.top);
        ScanChainData &scanchain = database.scanchain.at(database.top);

        YAML::Node node;

        node["width"] = DATA_WIDTH;

        node["ff"] = YAML::Node(YAML::NodeType::Sequence);
        for (auto &src : scanchain.ff) {
            YAML::Node ff_node;
            for (auto &c : src.info) {
                YAML::Node src_node;
                src_node["name"] = simple_hier_name(c.name);
                src_node["offset"] = c.offset;
                src_node["width"] = c.width;
                ff_node.push_back(src_node);
            }
            node["ff"].push_back(ff_node);
        }

        node["mem"] = YAML::Node(YAML::NodeType::Sequence);
        for (auto &mem : scanchain.mem) {
            YAML::Node mem_node;
            mem_node["name"] = simple_hier_name(mem.name);
            mem_node["width"] = mem.mem_width;
            mem_node["depth"] = mem.mem_depth;
            mem_node["start_offset"] = mem.mem_start_offset;
            node["mem"].push_back(mem_node);
        }

        for (auto &section : emulib) {
            YAML::Node emulib_node;
            for (auto &info : section.second) {
                emulib_node["name"] = simple_hier_name(info.name);
                for (auto &attr : info.attrs)
                    emulib_node[attr.first] = attr.second;
            }
            node[section.first].push_back(emulib_node);
        }

        os << node;
    }
} WriteYAMLWorker;

struct WriteLoaderWorker : public EmuDatabaseWorker {
    void operator()(std::string db_name, std::ostream &os) override {
        Database &database = Database::databases.at(db_name);

        if (database.top.empty()) {
            log_warning("Database %s is incomplete and ignored\n", db_name.c_str());
            return;
        }

        ScanChainData &scanchain = database.scanchain.at(database.top);

        int addr;

        os << "`define LOAD_DECLARE integer __load_i;\n";
        os << "`define LOAD_WIDTH " << DATA_WIDTH << "\n";

        os << "`define LOAD_FF(__LOAD_FF_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
        addr = 0;
        for (auto &src : scanchain.ff) {
            int offset = 0;
            for (auto info : src.info) {
                if (!info.is_public)
                    continue;
                std::string name = simple_hier_name(info.name);
                os  << "    __LOAD_DUT." << name
                    << "[" << info.width + info.offset - 1 << ":" << info.offset << "] = __LOAD_FF_DATA[__LOAD_OFFSET+" << addr << "]"
                    << "[" << info.width + offset - 1 << ":" << offset << "]; \\\n";
                offset += info.width;
            }
            addr++;
        }
        os << "\n";
        os << "`define CHAIN_FF_WORDS " << addr << "\n";

        os << "`define LOAD_MEM(__LOAD_MEM_DATA, __LOAD_OFFSET, __LOAD_DUT) \\\n";
        addr = 0;
        for (auto &mem : scanchain.mem) {
            if (!mem.is_public)
                continue;
            std::string name = simple_hier_name(mem.name);
            os  << "    for (__load_i=0; __load_i<" << mem.mem_depth << "; __load_i=__load_i+1) __LOAD_DUT."
                << name << "[__load_i+" << mem.mem_start_offset << "] = {";
            for (int i = mem.slices - 1; i >= 0; i--)
                os << "__LOAD_MEM_DATA[__LOAD_OFFSET+__load_i*" << mem.slices << "+" << addr + i << "]" << (i != 0 ? ", " : "");
            os << "}; \\\n";
            addr += mem.depth;
        }
        os << "\n";
        os << "`define CHAIN_MEM_WORDS " << addr << "\n";
    }
} WriteLoaderWorker;

struct EmuDatabasePass : public Pass {
    EmuDatabasePass() : Pass("emu_database", "manage emulation databases") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_database command [options]\n");
        log("\n");
        log("This command managements the databases used in emulator transformtaion flow.\n");
        log("\n");
        log("Commands:\n");
        log("    write_config\n");
        log("        write configuration in JSON format to the specified file.\n");
        log("    write_loader\n");
        log("        write loader code to the specified file.\n");
        log("    reset\n");
        log("        clean the specified database.\n");
        log("\n");
        log("Options:\n");
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("    -file <filename>\n");
        log("        write to specified file (otherwise STDOUT).\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_DATABASE pass.\n");

        std::string cmd;
        std::string db_name;
        std::string file_name;

        if (args.size() < 2)
            return;

        cmd = args[1];

        size_t argidx;
        for (argidx = 2; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-db" && argidx+1 < args.size()) {
                db_name = args[++argidx];
                continue;
            }
            if (args[argidx] == "-file" && argidx+1 < args.size()) {
                file_name = args[++argidx];
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        if (cmd == "reset") {
            Database::databases[db_name] = Database();
            return;
        }

        std::map<std::string, EmuDatabaseWorker&> cmdlist = {
            {"write_config",    WriteConfigWorker},
            {"write_yaml",      WriteYAMLWorker},
            {"write_loader",    WriteLoaderWorker},
        };

        if (cmdlist.find(cmd) == cmdlist.end())
            log_error("Invalid command %s", cmd.c_str());

        if (Database::databases.find(db_name) == Database::databases.end())
            log_error("Database not found\n");

        auto &worker = cmdlist.at(cmd);

        if (!file_name.empty()) {
            std::ofstream f;
            f.open(file_name.c_str(), std::ofstream::trunc);
            if (f.fail()) {
                log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
            }
            log("Writing to file `%s'\n", file_name.c_str());
            worker(db_name, f);
            f.close();
        }
        else {
            worker(db_name, std::cout);
        }
    }

} EmuDatabasePass;

PRIVATE_NAMESPACE_END