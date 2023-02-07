#ifndef _REMU_SCHEDULER_H_
#define _REMU_SCHEDULER_H_

#include <memory>
#include <queue>

#include "emu_info.h"
#include "driver.h"
#include "event.h"

namespace REMU {

class Scheduler
{
    SysInfo sysinfo;
    Driver drv;
    std::priority_queue<EventHandle> event_queue;

public:

    int main();

    Scheduler(
        const SysInfo &sysinfo,
        const DriverOptions &options,
        std::unique_ptr<UserMem> &&mem,
        std::unique_ptr<UserIO> &&reg
    )
    : sysinfo(sysinfo), drv(sysinfo, options, std::move(mem), std::move(reg)) {}
};

};

#endif
