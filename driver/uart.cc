#include "uart.h"

using namespace REMU;

void UartCallback::execute(Driver &drv) const
{
    char ch = drv.get_signal(tx_ch_index);
    printf("%c", ch);
    fflush(stdout);
}
