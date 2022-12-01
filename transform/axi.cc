#include "axi.h"
#include <stdexcept>

void AXI::__check_error(std::vector<const char*> &backtrace, const char *msg)
{
    std::string all_msg;
    for (auto bt : backtrace)
        all_msg += bt;
    all_msg += msg;
    throw std::runtime_error(all_msg);
}
