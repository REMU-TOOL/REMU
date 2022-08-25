#include "model.h"

using namespace Replay;

void FifoModel::load(const CircuitDataScope &circuit)
{
    fifo = decltype(fifo)();

    // assuming circuit is an instance of emulib_ready_valid_fifo

    // process output reg in emulib_ready_valid_fifo

    auto &ovalid = circuit.ff({"ovalid"});
    if (ovalid != 0)
        fifo.push(circuit.ff({"odata"}));

    // process emulib_fifo instance

    auto &rempty = circuit.ff({"fifo", "rempty"});
    if (rempty != 0)
        return;

    int rp = circuit.ff({"fifo", "rp"});
    int wp = circuit.ff({"fifo", "wp"});

    std::vector<std::string> data_name({"fifo", "data"});
    auto data_node = dynamic_cast<CircuitInfo::Mem*>(circuit.scope.get(data_name));
    if (data_node == nullptr)
        throw std::bad_cast();

    auto &data = circuit.mem(data_node->id);

    int depth = data_node->depth;
    int start_offset = data_node->start_offset;

    while (rp != wp) {
        fifo.push(data.get(rp++ - start_offset));
        if (rp == depth) rp = 0;
    }
}
