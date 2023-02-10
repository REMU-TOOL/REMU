#include "driver.h"

#include <cstdio>

#include "emu_utils.h"
#include "regdef.h"

using namespace REMU;

void Driver::init_trigger()
{
    for (auto &info : sysinfo.trigger) {
        om_trigger.add({
            .name           = flatten_name(info.name),
            .reg_index      = info.index,
        });
    }
    for (auto &trigger : om_trigger)
        set_trigger_enable(trigger.index, true);
}

bool Driver::is_trigger_active(int index)
{
    int id = om_trigger.get(index).reg_index;
    int addr = RegDef::TRIG_STAT_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

bool Driver::get_trigger_enable(int index)
{
    int id = om_trigger.get(index).reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

void Driver::set_trigger_enable(int index, bool enable)
{
    auto &trig = om_trigger.get(index);
    int id = trig.reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    if (enable)
        value |= (1 << offset);
    else
        value &= ~(1 << offset);
    reg->write(addr, value);
    fprintf(stderr, "[REMU] INFO: Trigger \"%s\" is %s\n",
        trig.name.c_str(), enable ? "enabled" : "disabled");
}

std::vector<int> Driver::get_active_triggers(bool enabled)
{
    std::vector<int> res;
    constexpr int nregs = (RegDef::TRIG_STAT_END - RegDef::TRIG_STAT_START) / 4;
    uint32_t values[nregs];
    for (int i = 0; i < nregs; i++) {
        values[i] = reg->read(RegDef::TRIG_STAT_START + 4*i);
        if (enabled)
            values[i] &= reg->read(RegDef::TRIG_EN_START + 4*i);
    }
    for (auto &trigger : om_trigger) {
        int id = trigger.reg_index;
        if (values[id / 32] & (1 << (id % 32)))
            res.push_back(trigger.index);
    }
    return res;
}
