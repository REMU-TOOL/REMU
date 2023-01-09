#ifndef _EMU_PLATFORM_H_
#define _EMU_PLATFORM_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"
#include "emulib.h"

namespace Emu {

struct PlatformTransform
{
    Yosys::Design *design;
    EmulationDatabase &database;
    EmuLibInfo &emulib;

    void connect_main_sigs(Yosys::Module *top, Yosys::Cell *emu_ctrl);
    void connect_resets(Yosys::Module *top, Yosys::Cell *emu_ctrl);
    void connect_triggers(Yosys::Module *top, Yosys::Cell *emu_ctrl);
    void connect_pipe_ports(Yosys::Module *top, Yosys::Cell *emu_ctrl);
    void connect_scanchain(Yosys::Module *top, Yosys::Cell *emu_ctrl);

    void run();

    PlatformTransform(Yosys::Design *design, EmulationDatabase &database, EmuLibInfo &emulib)
        : design(design), database(database), emulib(emulib) {}
};

};

#endif // #ifndef _EMU_PLATFORM_H_
