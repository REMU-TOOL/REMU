#include "model.h"

using namespace REMU;

void FifoModel::load(CircuitState &circuit, const CircuitPath &path)
{
    fifo = decltype(fifo)();

    // assuming circuit is an instance of emulib_ready_valid_fifo

    // process output reg in emulib_ready_valid_fifo

    auto &ovalid = circuit.wire.at(path / "ovalid");
    if (ovalid != 0)
        fifo.push(circuit.wire.at(path / "odata"));

    // process emulib_fifo instance

    auto &rempty = circuit.wire.at(path / "fifo" / "rempty");
    if (rempty != 0)
        return;

    int rp = circuit.wire.at(path / "fifo" / "rp");
    int wp = circuit.wire.at(path / "fifo" / "wp");

    // TODO: dissolved RAM
    auto &data = circuit.ram.at(path / "fifo" / "data");

    int depth = data.depth();
    int start_offset = data.start_offset();

    while (rp != wp) {
        fifo.push(data.get(rp++ - start_offset));
        if (rp == depth) rp = 0;
    }
}
