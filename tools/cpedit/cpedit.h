#ifndef _CPEDIT_H_
#define _CPEDIT_H_

#include "circuit.h"

namespace REMU {

class CpEdit
{
    CheckpointManager ckpt_mgr;
    Checkpoint ckpt;
    CircuitState circuit;

    std::unordered_map<std::string, size_t> axi_info;
    std::unordered_map<std::string, std::vector<std::string>> ff_name_map; // flattened -> original
    std::unordered_map<std::string, std::vector<std::string>> ram_name_map; // flattened -> original

    std::vector<std::pair<std::string, std::string>> pending_axi_imports; // axi name, file path

    uint64_t current_tick;

    void load(uint64_t tick);
    void save();

    bool cmd_help       (const std::vector<std::string> &args);
    bool cmd_list       (const std::vector<std::string> &args);
    bool cmd_current    (const std::vector<std::string> &args);
    bool cmd_axi        (const std::vector<std::string> &args);
    bool cmd_ff         (const std::vector<std::string> &args);
    bool cmd_ram        (const std::vector<std::string> &args);
    bool cmd_ff_dump    (const std::vector<std::string> &args);
    bool cmd_ram_dump   (const std::vector<std::string> &args);
    bool cmd_save       (const std::vector<std::string> &args);

    static std::unordered_map<std::string, decltype(&CpEdit::cmd_help)> cmd_dispatcher;

public:

    bool execute(std::string cmd);
    void run_cli();

    CpEdit(const SysInfo &sysinfo, const std::string &ckpt_path);
};

}

#endif
