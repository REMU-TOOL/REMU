#ifndef _REGDEF_H_
#define _REGDEF_H_

namespace REMU {

namespace RegDef
{
    constexpr int MODE_CTRL         = 0x000;
    constexpr int STEP_CNT          = 0x004;
    constexpr int TICK_CNT_LO       = 0x008;
    constexpr int TICK_CNT_HI       = 0x00c;
    constexpr int SCAN_CTRL         = 0x010;
    constexpr int TRIG_STAT_START   = 0x100;
    constexpr int TRIG_STAT_END     = 0x110;
    constexpr int TRIG_EN_START     = 0x110;
    constexpr int TRIG_EN_END       = 0x120;
    constexpr int RESET_CTRL_START  = 0x120;
    constexpr int RESET_CTRL_END    = 0x130;

    constexpr int MODE_CTRL_RUN_MODE    = (1 << 0);
    constexpr int MODE_CTRL_SCAN_MODE   = (1 << 1);
    constexpr int MODE_CTRL_PAUSE_BUSY  = (1 << 2);
    constexpr int MODE_CTRL_MODEL_BUSY  = (1 << 3);

    constexpr int SCAN_CTRL_RUNNING     = (1 << 0);
    constexpr int SCAN_CTRL_START       = (1 << 0);
    constexpr int SCAN_CTRL_DIRECTION   = (1 << 1);
};

};

#endif
