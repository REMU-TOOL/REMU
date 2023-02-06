#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <queue>

#include "emu_info.h"
#include "hal.h"
#include "event.h"

namespace REMU {

class Driver
{
    SysInfo sysinfo;
    HAL hal;
    std::priority_queue<EventHandle> event_queue;

public:

    int main();

    Driver(const SysInfo &sysinfo, std::unique_ptr<UserMem> &&mem, std::unique_ptr<UserIO> &&reg) :
        sysinfo(sysinfo), hal(std::move(mem), std::move(reg)) {}
};

};

#endif
