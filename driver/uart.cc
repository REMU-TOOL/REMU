#include "uart.h"

#include <cstdio>
#include <unistd.h>
#include <fcntl.h>

#include "driver.h"

using namespace REMU;

void UartModel::enter_term()
{
    if (term_mode)
        return;

    tcgetattr(0, &old_term);

    struct termios t = old_term;
    t.c_lflag &= ~ICANON;
    t.c_lflag &= ~ECHO;
    tcsetattr(0, TCSANOW, &t);

    old_fl = fcntl(0, F_GETFL);
    fcntl(0, F_SETFL, old_fl | O_NONBLOCK);

    term_mode = true;
}

void UartModel::exit_term()
{
    tcsetattr(0, TCSANOW, &old_term);
    fcntl(0, F_SETFL, old_fl);
    
    term_mode = false;
}

void UartModel::poll(Driver &driver)
{
    if (!driver.is_replay_mode()) {
        char ch = ch_to_send;
        ch_to_send = 0;
        if (!ch) {
            read(0, &ch, 1);
        }
        if (ch) {
            driver.pause();
            uint64_t tick = driver.current_tick();
            bool toggle = driver.get_signal_value(sig_rx_toggle).getBit(0);
            driver.set_signal_value(sig_rx_toggle, BitVector(1, !toggle));
            driver.set_signal_value(sig_rx_ch, BitVector(8, ch));
        }
    }

    char ch;
    while (driver.read_uart_data(ch)) {
        write(1, &ch, 1);
    }
}

bool UartModel::send(char ch)
{
    if (ch_to_send != 0)
        return false;

    ch_to_send = ch;
    return true;
}

UartModel::UartModel(Driver &driver, const std::string &name)
{
    sig_rx_toggle = driver.lookup_signal(name + ".rx_tx_imp._rx_toggle");
    sig_rx_ch = driver.lookup_signal(name + ".rx_tx_imp._rx_ch");

    term_mode = false;
}
