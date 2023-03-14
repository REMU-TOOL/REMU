#include "uart.h"

#include <cstdio>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

using namespace REMU;

void UartModel::init_term()
{
    struct termios t;
    tcgetattr(0, &t);
    t.c_lflag &= ~ICANON;
    tcsetattr(0, TCSANOW, &t);

    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
}

bool UartModel::handle_tx(Driver &drv)
{
    char ch = drv.get_signal_value(sig_tx_ch);
    printf("%c", ch);
    fflush(stdout);
    return true;
}

bool UartModel::handle_rx(Driver &drv)
{
    if (drv.is_replay_mode())
        return false;

    if (drv.current_tick() < next_rx_tick)
        return false;

    char ch = 0;
    read(0, &ch, 1);
    if (ch) {
        drv.pause();
        uint64_t tick = drv.current_tick();
        drv.set_signal_value(sig_rx_valid, BitVector(1, 1), tick);
        drv.set_signal_value(sig_rx_ch, BitVector(8, ch), tick);
        drv.set_signal_value(sig_rx_valid, BitVector(1, 0), tick + 1);
        next_rx_tick = tick + 1;
        return true;
    }

    return false;
}

UartModel::UartModel(Driver &drv, const std::string &name)
{
    trig_tx_valid = drv.lookup_trigger(name + ".rx_tx_imp._tx_valid");
    sig_tx_ch = drv.lookup_signal(name + ".rx_tx_imp._tx_ch");
    sig_rx_valid = drv.lookup_signal(name + ".rx_tx_imp._rx_valid");
    sig_rx_ch = drv.lookup_signal(name + ".rx_tx_imp._rx_ch");

    next_rx_tick = 0;

    drv.register_trigger_callback(trig_tx_valid, [this](Driver &drv) { return this->handle_tx(drv); });
    drv.register_parallel_callback([this](Driver &drv) { return this->handle_rx(drv); });

    init_term();
}
