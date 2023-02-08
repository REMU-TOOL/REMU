#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include "driver.h"

namespace REMU {

class UartTxCallback : public Callback
{
    int tx_ch_index;

public:

    virtual void execute(Driver &drv) const override;

    UartTxCallback(int tx_ch_index) : tx_ch_index(tx_ch_index) {}
};

class UartRxWorker
{
    Driver &drv;
    int rx_valid_index;
    int rx_ch_index;

public:

    void init();
    void handle_input();

    UartRxWorker(Driver &drv, int rx_valid_index, int rx_ch_index) :
        drv(drv), rx_valid_index(rx_valid_index), rx_ch_index(rx_ch_index)
    {
        init();
    }
};

}

#endif
