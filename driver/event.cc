#include "driver.h"

using namespace REMU;

void BreakEvent::execute(Driver &drv) const
{
    drv.running = false;
}

void SignalEvent::execute(Driver &drv) const
{
    drv.set_signal(index, value);
}
