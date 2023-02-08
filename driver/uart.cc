#include "uart.h"

#include <cstdio>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

using namespace REMU;

void UartCallback::callback(Driver &) const
{
    handler.handle_tx();
}

void UartHandler::init_term()
{
    struct termios t;
    tcgetattr(0, &t);
    t.c_lflag &= ~ICANON;
    tcsetattr(0, TCSANOW, &t);

    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
}

void UartHandler::handle_tx()
{
    char ch = drv.get_signal_value(sig_tx_ch);
    printf("%c", ch);
    fflush(stdout);
}

void UartHandler::handle_rx()
{
    // FIXME: read tick count in run mode is risky
    if (drv.get_tick_count() < next_rx_tick)
        return;

    char ch = 0;
    read(0, &ch, 1);
    if (ch) {
        drv.exit_run_mode();
        uint64_t tick = drv.get_tick_count();
        drv.schedule_event(new SignalEvent(tick, sig_rx_valid, BitVector(1, 1)));
        drv.schedule_event(new SignalEvent(tick, sig_rx_ch, BitVector(8, ch)));
        drv.schedule_event(new SignalEvent(tick + 1, sig_rx_valid, BitVector(1, 0)));
        next_rx_tick = tick + 1;
    }
}

UartHandler::UartHandler(Driver &drv, const std::string &name) : drv(drv), callback(*this)
{
    trig_tx_valid = drv.lookup_trigger(name + ".rx_tx_imp._tx_valid");
    sig_tx_ch = drv.lookup_signal(name + ".rx_tx_imp._tx_ch");
    sig_rx_valid = drv.lookup_signal(name + ".rx_tx_imp._rx_valid");
    sig_rx_ch = drv.lookup_signal(name + ".rx_tx_imp._rx_ch");

    next_rx_tick = 0;

    drv.register_trigger_callback(trig_tx_valid, &callback);

    init_term();
}

UartHandler::~UartHandler()
{
    drv.unregister_trigger_callback(trig_tx_valid);
}
