#define EMU_STAT                0x000
#define EMU_TRIG_STAT           0x004
#define EMU_CYCLE_LO            0x008
#define EMU_CYCLE_HI            0x00c
#define EMU_STEP                0x010
#define EMU_CKPT_SIZE           0x014
#define EMU_DMA_ADDR_LO         0x020
#define EMU_DMA_ADDR_HI         0x024
#define EMU_DMA_STAT            0x028
#define EMU_DMA_CTRL            0x02c

#define EMU_STAT_PAUSE          (1 << 0)
#define EMU_STAT_DUT_RESET      (1 << 1)
#define EMU_STAT_STEP_TRIG      (1 << 31)
#define EMU_DMA_STAT_RUNNING    (1 << 0)
#define EMU_DMA_CTRL_START      (1 << 0)
#define EMU_DMA_CTRL_DIRECTION  (1 << 1)

