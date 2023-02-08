#include "uart.h"

#include <cstdio>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

using namespace REMU;

void UartTxCallback::execute(Driver &drv) const
{
    char ch = drv.get_signal(tx_ch_index);
    printf("%c", ch);
    fflush(stdout);
}

void UartRxWorker::init()
{
    struct termios t;
    tcgetattr(0, &t);
    t.c_lflag &= ~ICANON;
    tcsetattr(0, TCSANOW, &t);

    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
}

void UartRxWorker::handle_input()
{
    char ch = 0;
    read(0, &ch, 1);
    if (ch) {
        drv.exit_run_mode();
        uint64_t tick = drv.get_tick_count();
        drv.schedule_event(new SignalEvent(tick, rx_valid_index, BitVector(1, 1)));
        drv.schedule_event(new SignalEvent(tick, rx_ch_index, BitVector(8, ch)));
        drv.schedule_event(new SignalEvent(tick + 1, rx_valid_index, BitVector(1, 0)));
    }
}
