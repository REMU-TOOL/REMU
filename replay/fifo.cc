#include "model.h"

using namespace REMU;

void REMU::load_fifo(std::queue<BitVector> &fifo, CircuitState &circuit, const CircuitPath &path)
{
    // assuming circuit is an instance of emulib_fifo

    // TODO: FAST_READ = 1

    auto &rempty = circuit.wire.at(path / "rempty").data;
    if (rempty != 0)
        return;

    int rp = circuit.wire.at(path / "rp").data;
    int wp = circuit.wire.at(path / "wp").data;

    // TODO: dissolved RAM
    auto &data = circuit.ram.at(path / "data").data;

    int depth = data.depth();
    int start_offset = data.start_offset();

    while (rp != wp) {
        fifo.push(data.get(rp++ - start_offset));
        if (rp == depth) rp = 0;
    }
}

void REMU::load_ready_valid_fifo(std::queue<BitVector> &fifo, CircuitState &circuit, const CircuitPath &path)
{
    // assuming circuit is an instance of emulib_ready_valid_fifo

    // TODO: FAST_READ = 1

    // process output reg in emulib_ready_valid_fifo

    auto &ovalid = circuit.wire.at(path / "ovalid").data;
    if (ovalid != 0)
        fifo.push(circuit.wire.at(path / "odata").data);

    // process emulib_fifo instance

    load_fifo(fifo, circuit, path / "fifo");
}
