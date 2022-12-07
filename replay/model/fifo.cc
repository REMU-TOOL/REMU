#include "model.h"

using namespace Replay;

void FifoModel::load(CircuitInfo *circuit)
{
    fifo = decltype(fifo)();

    // assuming circuit is an instance of emulib_ready_valid_fifo

    // process output reg in emulib_ready_valid_fifo

    auto &ovalid = circuit->reg({"ovalid"}).data;
    if (ovalid != 0)
        fifo.push(circuit->reg({"odata"}).data);

    // process emulib_fifo instance

    auto &rempty = circuit->reg({"fifo", "rempty"}).data;
    if (rempty != 0)
        return;

    int rp = circuit->reg({"fifo", "rp"}).data;
    int wp = circuit->reg({"fifo", "wp"}).data;

    // TODO: dissolved RAM
    auto &regarray = circuit->regarray({"fifo", "data"});

    int depth = regarray.data.depth();
    int start_offset = regarray.start_offset;

    while (rp != wp) {
        fifo.push(regarray.data.get(rp++ - start_offset));
        if (rp == depth) rp = 0;
    }
}
