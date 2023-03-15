#include "sighandler.h"
#include <csignal>
#include <stdexcept>

using namespace REMU;

namespace {

struct SigIntDispatcher
{
    std::function<void()> active_handler;
    static void sys_handler(int);
    SigIntDispatcher();
};

struct SigIntDispatcher dispatcher;

void SigIntDispatcher::sys_handler(int)
{
    if (dispatcher.active_handler)
        dispatcher.active_handler();
}

SigIntDispatcher::SigIntDispatcher()
{
    signal(SIGINT, sys_handler);
}

} // namespace

SigIntHandler::SigIntHandler(std::function<void()> handler)
{
    if (dispatcher.active_handler)
        throw std::runtime_error("try to register multiple SIGINT handler");

    dispatcher.active_handler = handler;
}

SigIntHandler::~SigIntHandler()
{
    dispatcher.active_handler = 0;
}
