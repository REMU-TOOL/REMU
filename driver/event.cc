#include "driver.h"

using namespace REMU;

void SignalEvent::execute(Driver &drv) const
{
    drv.set_signal(handle, value);
}
