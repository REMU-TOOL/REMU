#include "checkpoint.h"

#include <set>
#include <string>
#include <sstream>

using namespace REMU;

uint64_t Checkpoint::getTick()
{
    auto istream = readItem("tick");
    uint64_t tick = 0;
    istream.read(reinterpret_cast<char*>(&tick), sizeof(tick));
    return tick;
}

void Checkpoint::setTick(uint64_t tick)
{
    auto ostream = writeItem("tick");
    ostream.write(reinterpret_cast<char*>(&tick), sizeof(tick));
}
