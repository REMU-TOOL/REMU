#include "cpedit.h"
#include "tokenizer.h"
#include "emu_utils.h"

#include <cstdio>
#include <cstring>

#include <unordered_map>

#include <readline/readline.h>
#include <readline/history.h>

using namespace REMU;
namespace tk = Tokenizer;

void CpEdit::load(uint64_t tick)
{
    fprintf(stderr, "Load checkpoint at tick %ld\n", tick);

    current_tick = tick;
    ckpt = ckpt_mgr.open(tick);
    ckpt_mgr.flush();
    circuit.load(ckpt);
}

void CpEdit::save()
{
    fprintf(stderr, "Save checkpoint at tick %ld\n", current_tick);

    circuit.save(ckpt);

    for (auto &it : pending_axi_imports) {
        fprintf(stderr, "Import AXI %s with file %s\n",
            it.first.c_str(), it.second.c_str());

        auto &mem = ckpt.axi_mems.at(it.first);
        mem.load(it.second);
        mem.flush();
    }
    pending_axi_imports.clear();
}

bool CpEdit::cmd_help(const std::vector<std::string> &args)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Commands:\n"
        "    help\n"
        "        Show this help message.\n"
        "    list\n"
        "        List checkpointed ticks.\n"
        "    current [<tick>]\n"
        "        Get/set current tick. Setting tick value will cause the corresponding \n"
        "        checkpoint to be loaded. The default tick is 0.\n"
        "    axi\n"
        "        List AXI memories.\n"
        "    axi import <axi> <file>\n"
        "        Import data to AXI memory from the specified file.\n"
        "    axi export <axi> <file>\n"
        "        Export data from AXI memory to the specified file.\n"
        "    ff \n"
        "        List FFs.\n"
        "    ff <name> [<value>]\n"
        "        Get/set FF value in binary form.\n"
        "    ram\n"
        "        List RAMs.\n"
        "    ram <name>\n"
        "        Get RAM dimension infomation.\n"
        "    ram <name> <index> [<value>]\n"
        "        Get/set RAM value at the specified index in binary form.\n"
        "    ff-dump\n"
        "        Dump FF values.\n"
        "    ram-dump\n"
        "        Dump RAM values.\n"
        "    ram-dump <name>\n"
        "        Dump values of the specified RAM.\n"
        "    save\n"
        "        Save checkpoint changes.\n"
        "\n"
        );

    return true;
}

bool CpEdit::cmd_list(const std::vector<std::string> &args)
{
    printf("Checkpointed ticks:\n");
    for (auto tick : ckpt_mgr.ticks) {
        printf("%ld\n", tick);
    }

    return true;
}

bool CpEdit::cmd_current(const std::vector<std::string> &args)
{
    if (args.size() == 1) {
        printf("Current tick: %ld\n", current_tick);
    }
    else if (args.size() == 2) {
        uint64_t tick = std::stoul(args[1]);
        if (!ckpt_mgr.has_tick(tick)) {
            fprintf(stderr, "Tick %ld is not checkpointed\n", tick);
            return false;
        }
        load(tick);
    }
    else {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }
    return true;
}

bool CpEdit::cmd_axi(const std::vector<std::string> &args)
{
    if (args.size() == 1) {
        for (auto &it : axi_info) {
            printf("%s\n", it.first.c_str());
        }
        return true;
    }

    if (args.size() != 4) {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    auto action = args[1];
    auto axi_name = args[2];
    auto file_name = args[3];

    if (action == "import") {
        if (axi_info.find(axi_name) == axi_info.end()) {
            fprintf(stderr, "AXI %s does not exist\n", axi_name.c_str());
            return false;
        }

        pending_axi_imports.push_back(std::make_pair(axi_name, file_name));

        fprintf(stderr, "AXI import action queued\n");
        return true;
    }
    else if (action == "export") {
        if (axi_info.find(axi_name) == axi_info.end()) {
            fprintf(stderr, "AXI %s does not exist\n", axi_name.c_str());
            return false;
        }

        fprintf(stderr, "Export AXI %s to file %s\n",
            axi_name.c_str(), file_name.c_str());

        ckpt.axi_mems.at(axi_name).save(file_name);
        return true;
    }

    fprintf(stderr, "Unknown subcommand %s\n", action.c_str());
    return false;
}

bool CpEdit::cmd_ff(const std::vector<std::string> &args)
{
    if (args.size() > 3) {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    if (args.size() == 1) {
        for (auto &it : ff_name_map) {
            printf("%s\n", it.first.c_str());
        }
        return true;
    }

    std::string ff_name = args[1];
    if (ff_name_map.find(ff_name) == ff_name_map.end()) {
        fprintf(stderr, "FF %s does not exist\n", ff_name.c_str());
        return false;
    }

    auto &data = circuit.wire.at(ff_name_map.at(ff_name));

    if (args.size() == 2) {
        printf("%s\n", data.bin().c_str());
        return true;
    }

    std::string value = args[2];
    if (value.size() != data.width()) {
        fprintf(stderr, "Value width must be %lu\n", data.width());
        return false;
    }

    data = BitVector(args[2]);
    return true;
}

bool CpEdit::cmd_ram(const std::vector<std::string> &args)
{
    if (args.size() > 4) {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    if (args.size() == 1) {
        for (auto &it : ram_name_map) {
            printf("%s\n", it.first.c_str());
        }
        return true;
    }

    std::string ram_name = args[1];
    if (ram_name_map.find(ram_name) == ram_name_map.end()) {
        fprintf(stderr, "RAM %s does not exist\n", ram_name.c_str());
        return false;
    }

    auto &data = circuit.ram.at(ram_name_map.at(ram_name));

    if (args.size() == 2) {
        printf("Width: %lu\n", data.width());
        printf("Depth: %ld\n", data.depth());
        printf("Start Offset: %ld\n", data.start_offset());
        return true;
    }

    int64_t index = std::stol(args[2]);

    if (args.size() == 3) {
        printf("%s\n", data.get(index).bin().c_str());
        return true;
    }

    std::string value = args[3];
    if (value.size() != data.width()) {
        fprintf(stderr, "Value width must be %lu\n", data.width());
        return false;
    }

    data.set(index, BitVector(value));
    return true;
}

bool CpEdit::cmd_ff_dump(const std::vector<std::string> &args)
{
    if (args.size() != 1) {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    for (auto &it : circuit.wire) {
        printf("%s = %lu'h%s\n",
            flatten_name(it.first).c_str(),
            it.second.width(), it.second.hex().c_str());
    }

    return true;
}

static void dump_ram(const decltype(*CircuitState::ram.begin()) &it)
{
    int width = it.second.width();
    int depth = it.second.depth();
    int start_offset = it.second.start_offset();
    for (int i = 0; i < depth; i++) {
        auto word = it.second.get(i);
        printf("%s[%d] = %lu'h%s\n",
            flatten_name(it.first).c_str(),
            i + start_offset, word.width(), word.hex().c_str());
    }
}

bool CpEdit::cmd_ram_dump(const std::vector<std::string> &args)
{
    if (args.size() == 1) {
        for (auto &it : circuit.ram) {
            dump_ram(it);
        }
    }
    else if (args.size() == 2) {
        std::string ram_name = args[1];
        if (ram_name_map.find(ram_name) == ram_name_map.end()) {
            fprintf(stderr, "RAM %s does not exist\n", ram_name.c_str());
            return false;
        }

        auto it = circuit.ram.find(ram_name_map.at(ram_name));
        dump_ram(*it);
    }
    else  {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    return true;
}

bool CpEdit::cmd_save(const std::vector<std::string> &args)
{
    save();
    return true;
}

decltype(CpEdit::cmd_dispatcher) CpEdit::cmd_dispatcher = {
    {"help",        &CpEdit::cmd_help},
    {"list",        &CpEdit::cmd_list},
    {"current",     &CpEdit::cmd_current},
    {"axi",         &CpEdit::cmd_axi},
    {"ff",          &CpEdit::cmd_ff},
    {"ram",         &CpEdit::cmd_ram},
    {"ff-dump",     &CpEdit::cmd_ff_dump},
    {"ram-dump",    &CpEdit::cmd_ram_dump},
    {"save",        &CpEdit::cmd_save},
};

bool CpEdit::execute(std::string cmd)
{
    auto args = tk::tokenize(cmd);
    if (args.size() == 0)
        return true;

    auto it = cmd_dispatcher.find(args[0]);
    if (it == cmd_dispatcher.end()) {
        fprintf(stderr, "Unrecognized command %s, enter \"help\" for available commands\n", args[0].c_str());
        return false;
    }

    return (this->*(it->second))(args);
}

void CpEdit::run_cli()
{
    while (true) {
        char *line = readline("cpedit> ");
        if (!line)
            break;

        add_history(line);

        std::string cmd(line);
        free(line);

        if (cmd == "exit")
            break;

        execute(cmd);
    }
}

CpEdit::CpEdit(const SysInfo &sysinfo, const std::string &ckpt_path) :
    ckpt_mgr(sysinfo, ckpt_path),
    ckpt(ckpt_mgr.open(0)),
    circuit(sysinfo)
{
    for (auto &it : sysinfo.wire) {
        ff_name_map[flatten_name(it.first)] = it.first;
    }

    for (auto &it : sysinfo.ram) {
        ram_name_map[flatten_name(it.first)] = it.first;
    }

    for (auto &axi : sysinfo.axi) {
        axi_info[flatten_name(axi.name)] = axi.size;
    }

    load(0);
}
