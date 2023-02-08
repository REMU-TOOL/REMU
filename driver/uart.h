#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include "driver.h"

namespace REMU {

class UartCallback : public Callback
{
    int tx_ch_index;

public:

    virtual void execute(Driver &drv) const override;

    UartCallback(int tx_ch_index) : tx_ch_index(tx_ch_index) {}
};

}

#endif
