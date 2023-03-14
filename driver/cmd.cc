#include "driver.h"
#include "tokenizer.h"

#include <readline/readline.h>
#include <readline/history.h>

using namespace REMU;
namespace tk = Tokenizer;

bool Driver::cmd_help(const std::vector<std::string> &args)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Commands:\n"
        "    help\n"
        "        Show this help message.\n"
        "    list\n"
        "        List checkpointed ticks.\n"
        "    save\n"
        "        Save a checkpoint of current tick.\n"
        "    replay <tick>\n"
        "        Load the checkpoint of specified tick or the latest one before it.\n"
        "        Emulation will be run in replay mode.\n"
        "    record <tick>\n"
        "        Load the checkpoint of specified tick or the latest one before it.\n"
        "        Emulation will be run in record mode. Checkpoints after the tick will\n"
        "        be removed.\n"
        "    ckpt_interval [<interval>]\n"
        "        Get/set checkpoint interval\n"
        "    run [<tick>]\n"
        "        Run emulation (to the specified tick).\n"
        "    trigger status <trigger>\n"
        "        Show trigger status.\n"
        "    trigger enable <trigger>\n"
        "        Enable trigger.\n"
        "    trigger disable <trigger>\n"
        "        Disable trigger.\n"
        "    signal\n"
        "        List signals.\n"
        "    signal <signal>\n"
        "        Get signal value.\n"
        "    signal <signal> <value> [<tick>]\n"
        "        Change signal value immediately or at the specified tick.\n"
        "\n"
        );

    return true;
}

bool Driver::cmd_list(const std::vector<std::string> &args)
{
    printf("Checkpointed ticks:\n");
    for (auto tick : ckpt_mgr.ticks) {
        printf("%ld\n", tick);
    }

    return true;
}

bool Driver::cmd_save(const std::vector<std::string> &args)
{
    save_checkpoint();
    return true;
}

bool Driver::cmd_replay_record(const std::vector<std::string> &args)
{
    if (args.size() != 2) {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    bool record = args[0] == "record";

    uint64_t tick = std::stoul(args[1]);
    cur_tick = ckpt_mgr.find_latest(tick);
    load_checkpoint(record);

    return true;
}

bool Driver::cmd_run(const std::vector<std::string> &args)
{
    if (args.size() == 1) {
        run();
    }
    else if (args.size() == 2) {
        auto tick = std::stoul(args[1]);
        if (tick <= cur_tick) {
            fprintf(stderr, "Specified tick must be greater than current tick\n");
            return false;
        }
        meta_event_q.push({tick, Stop});
        run();
    }
    else {
        fprintf(stderr, "Incorrect number of arguments for this command\n");
        return false;
    }

    return true;
}

bool Driver::cmd_signal(const std::vector<std::string> &args)
{
    if (args.size() == 1) {
        for (auto &signal : signal_db.objects()) {
            printf("%s\n", signal.name.c_str());
        }
        return true;
    }

    auto name = args[1];
    if (!signal_db.has(name)) {
        fprintf(stderr, "Signal %s does not exist\n", name.c_str());
        return false;
    }

    int index = signal_db.index_by_name(name);
    auto &signal = signal_db.object_by_index(index);

    if (args.size() == 2) {
        printf("%s\n", get_signal_value(index).bin().c_str());
        return true;
    }

    if (signal.output) {
        fprintf(stderr, "Cannot set output signal value\n");
        return false;
    }

    BitVector value(args[2]);
    if (value.width() != signal.width) {
        fprintf(stderr, "Wrong signal width (%d required)\n", signal.width);
        return false;
    }

    if (args.size() == 3) {
        set_signal_value(signal, value);
        return true;
    }

    uint64_t tick = std::stoul(args[3]);

    if (args.size() == 4) {
        set_signal_value(index, value, tick);
        return true;
    }

    fprintf(stderr, "Incorrect number of arguments for this command\n");
    return false;
}

decltype(Driver::cmd_dispatcher) Driver::cmd_dispatcher = {
    {"help",        &Driver::cmd_help},
    {"list",        &Driver::cmd_list},
    {"save",        &Driver::cmd_save},
    {"replay",      &Driver::cmd_replay_record},
    {"record",      &Driver::cmd_replay_record},
    {"run",         &Driver::cmd_run},
    {"signal",      &Driver::cmd_signal},
};

bool Driver::execute_cmd(const std::string &cmd)
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

void Driver::run_cli()
{
    while (true) {
        char buf[64];
        snprintf(buf, sizeof(buf), "[REMU %s @ %lu]> ", is_replay_mode() ? "replaying" : "recording", cur_tick);

        char *line = readline(buf);
        if (!line)
            break;

        add_history(line);

        std::string cmd(line);
        free(line);

        if (cmd == "exit")
            break;

        execute_cmd(cmd);
    }
}
