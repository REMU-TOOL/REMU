#include "kernel/yosys.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuDatabaseWorker {
    virtual void operator()(std::string db_name, std::string top_name, std::ostream &os) = 0;
};

struct WriteConfigWorker : public EmuDatabaseWorker {
    void operator()(std::string db_name, std::string top_name, std::ostream &os) override {
        Database &database = Database::databases.at(db_name);
        JsonWriter json(os);

        json.key("width").value(DATA_WIDTH);

        json.key("scanchain").enter_array();
        for (auto &it : database.scanchain) {
            if (!top_name.empty() && it.first != top_name)
                continue;

            json.enter_object();
            json.key("module").string(str_id(it.first));

            int ff_addr = 0;
            json.key("ff").enter_array();
            for (auto &src : it.second.ff) {
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
            for (auto &mem : it.second.mem) {
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

            json.back();
        }
        json.back();

        json.key("emulib").enter_array();
        for (auto &it : database.emulib) {
            if (!top_name.empty() && it.first != top_name)
                continue;

            json.enter_object();
            json.key("module").string(str_id(it.first));

            int clk_addr = 0;
            json.key("clock").enter_array();
            for (auto &clk : it.second.clk) {
                json.enter_object();
                json.key("addr").value(clk_addr);
                json.key("name").enter_array();
                for (auto &s : clk.name)
                    json.string(s);
                json.back();
                json.key("cycle_ps").value(clk.cycle_ps);
                json.key("phase_ps").value(clk.phase_ps);
                json.back();
                clk_addr++;
            }
            json.back();

            int rst_addr = 0;
            json.key("reset").enter_array();
            for (auto &rst : it.second.rst) {
                json.enter_object();
                json.key("addr").value(rst_addr);
                json.key("name").enter_array();
                for (auto &s : rst.name)
                    json.string(s);
                json.back();
                json.key("duration_ns").value(rst.duration_ns);
                json.back();
                rst_addr++;
            }
            json.back();

            int trig_addr = 0;
            json.key("trigger").enter_array();
            for (auto &trig : it.second.trig) {
                json.enter_object();
                json.key("addr").value(trig_addr);
                json.key("name").enter_array();
                for (auto &s : trig.name)
                    json.string(s);
                json.back();
                json.back();
                trig_addr++;
            }
            json.back();

            json.back();
        }
        json.back();

        json.end();
    }
} WriteConfigWorker;

struct WriteLoaderWorker : public EmuDatabaseWorker {
    void operator()(std::string db_name, std::string top_name, std::ostream &os) override {
        Database &database = Database::databases.at(db_name);
        ScanChainData &scanchain = database.scanchain.at(top_name);
        EmulibData &emulib = database.emulib.at(top_name);

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
                std::string name = verilog_hier_name(info.name);
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
            std::string name = verilog_hier_name(mem.name);
            os  << "    for (__load_i=0; __load_i<" << mem.mem_depth << "; __load_i=__load_i+1) __LOAD_DUT."
                << name << "[__load_i+" << mem.mem_start_offset << "] = {";
            for (int i = mem.slices - 1; i >= 0; i--)
                os << "__LOAD_MEM_DATA[__LOAD_OFFSET+__load_i*" << mem.slices << "+" << addr + i << "]" << (i != 0 ? ", " : "");
            os << "}; \\\n";
            addr += mem.depth;
        }
        os << "\n";
        os << "`define CHAIN_MEM_WORDS " << addr << "\n";

        os << "`define DUT_CLK_COUNT " << emulib.clk.size() << "\n";
        os << "`define DUT_RST_COUNT " << emulib.rst.size() << "\n";
        os << "`define DUT_TRIG_COUNT " << emulib.trig.size() << "\n";
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
        log("        write loader code to the specified file (implies -top).\n");
        log("    reset\n");
        log("        clean the specified database.\n");
        log("\n");
        log("Options:\n");
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("    -file <filename>\n");
        log("        write to specified file (otherwise STDOUT).\n");
        log("    -top\n");
        log("        write information in top module only.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_DATABASE pass.\n");

        std::string cmd;
        std::string db_name;
        std::string file_name;
        bool top = false;

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
            if (args[argidx] == "-top") {
                top = true;
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
            {"write_loader",    WriteLoaderWorker},
        };

        if (cmdlist.find(cmd) == cmdlist.end())
            log_error("Invalid command %s", cmd.c_str());

        if (cmd == "write_loader")
            top = true;

        if (Database::databases.find(db_name) == Database::databases.end())
            log_error("Database not found\n");

        // find top module
        std::string top_name;
        if (top) {
            top_name = Database::databases.at(db_name).top_name;
            if (top_name.empty()) {
                Module *top_module = design->top_module();
                if (!top_module)
                    log_error("No top module found\n");
                top_name = top_module->name.str();
            }
        }

        auto &worker = cmdlist.at(cmd);

        if (!file_name.empty()) {
            std::ofstream f;
            f.open(file_name.c_str(), std::ofstream::trunc);
            if (f.fail()) {
                log_error("Can't open file `%s' for writing: %s\n", file_name.c_str(), strerror(errno));
            }
            log("Writing to file `%s'\n", file_name.c_str());
            worker(db_name, top_name, f);
            f.close();
        }
        else {
            worker(db_name, top_name, std::cout);
        }
    }

} EmuDatabasePass;

PRIVATE_NAMESPACE_END