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

void UartModel::save(std::ostream &stream) const
{
    stream << rx_ready;
}

void UartModel::load(std::istream &stream)
{
    stream >> rx_ready;
}

bool UartModel::handle_realtime_callback(Driver &driver)
{
    if (!driver.is_replay_mode() && rx_ready) {
        char ch = 0;
        read(0, &ch, 1);
        if (ch) {
            driver.pause();
            uint64_t tick = driver.current_tick();
            driver.set_signal_value(sig_rx_valid, BitVector(1, 1));
            driver.set_signal_value(sig_rx_ch, BitVector(8, ch));
            driver.register_tick_callback(this, tick + 1);
            rx_ready = false;
        }
    }

    char ch;
    while (driver.read_uart_data(ch)) {
        write(1, &ch, 1);
    }

    return true;
}

bool UartModel::handle_tick_callback(Driver &driver, uint64_t /*tick*/)
{
    driver.set_signal_value(sig_rx_valid, BitVector(1, 0));
    rx_ready = true;
    return true;
}

UartModel::UartModel(Driver &driver, const std::string &name) : EmuModel(name)
{
    sig_rx_valid = driver.lookup_signal(name + ".rx_tx_imp._rx_valid");
    sig_rx_ch = driver.lookup_signal(name + ".rx_tx_imp._rx_ch");

    rx_ready = true;

    driver.register_realtime_callback(this);

    init_term();
}
