#ifndef _EMU_TRANSFORM_CLOCK_H_
#define _EMU_TRANSFORM_CLOCK_H_

#include "kernel/yosys.h"

#include "utils.h"

namespace REMU {

inline Yosys::IdString to_ff_clk(Yosys::SigBit clk) { return "\\" + Yosys::pretty_name(clk, false) + "_FF"; }
inline Yosys::IdString to_ram_clk(Yosys::SigBit clk) { return "\\" + Yosys::pretty_name(clk, false) + "_RAM"; }
inline Yosys::IdString clk_to_tick(Yosys::SigBit clk) { return "\\" + Yosys::pretty_name(clk, false) + "_TICK"; }

};

#endif // #ifndef _EMU_TRANSFORM_CLOCK_H_
