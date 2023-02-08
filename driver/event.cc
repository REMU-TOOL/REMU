#include "event.h"
#include "driver.h"

using namespace REMU;

bool SignalEvent::execute(Driver &drv) const
{
    drv.set_signal_value(index, value);
    return true;
}
