#include "driver.h"

#include <cstdio>
#include <stdexcept>

#include "emu_utils.h"
#include "regdef.h"

using namespace REMU;

void Driver::init_signal()
{
    for (auto &info : sysinfo.signal) {
        om_signal.add({
            .name           = flatten_name(info.name),
            .width          = info.width,
            .output         = info.output,
            .reg_offset     = info.reg_offset,
        });
    }
    for (auto &signal : om_signal)
        if (!signal.output)
            set_signal_value(signal.index, BitVector(signal.width, 0));
}

BitVector Driver::get_signal_value(int index)
{
    auto &sig = om_signal.get(index);
    int nblks = (sig.width + 31) / 32;
    BitVector res(sig.width);
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(sig.width - offset, 32);
        res.setValue(offset, width, reg->read(sig.reg_offset + i * 4));
    }
    return res;
}

void Driver::set_signal_value(int index, const BitVector &value)
{
    auto &sig = om_signal.get(index);

    if (sig.output)
        return;

    if (value.width() != sig.width)
        throw std::invalid_argument("value width mismatch");

    int nblks = (sig.width + 31) / 32;
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(sig.width - offset, 32);
        reg->write(sig.reg_offset + i * 4, value.getValue(offset, width));
    }

#if 0
    auto name = get_signal_name(index);
    fprintf(stderr, "[REMU] INFO: Tick %ld: set signal \"%s\" to %s\n",
        get_tick_count(), name.c_str(), value.bin().c_str());
#endif
}
