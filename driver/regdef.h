#ifndef _REGDEF_H_
#define _REGDEF_H_

namespace REMU {

namespace RegDef
{
    const int MODE_CTRL         = 0x000;
    const int STEP_CNT          = 0x004;
    const int TICK_CNT_LO       = 0x008;
    const int TICK_CNT_HI       = 0x00c;
    const int SCAN_CTRL         = 0x010;
    const int DMA_BASE          = 0x014;
    const int TRIG_STAT_START   = 0x100;
    const int TRIG_STAT_END     = 0x110;
    const int TRIG_EN_START     = 0x110;
    const int TRIG_EN_END       = 0x120;
    const int RESET_CTRL_START  = 0x120;
    const int RESET_CTRL_END    = 0x130;

    const int MODE_CTRL_RUN_MODE    = (1 << 0);
    const int MODE_CTRL_SCAN_MODE   = (1 << 1);
    const int MODE_CTRL_PAUSE_BUSY  = (1 << 2);
    const int MODE_CTRL_MODEL_BUSY  = (1 << 3);

    const int SCAN_CTRL_RUNNING     = (1 << 0);
    const int SCAN_CTRL_START       = (1 << 0);
    const int SCAN_CTRL_DIRECTION   = (1 << 1);
};

};

#endif
