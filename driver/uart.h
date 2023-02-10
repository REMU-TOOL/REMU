#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include "driver.h"
namespace REMU {

class UartModel : public DriverModel
{
    int trig_tx_valid;
    int sig_tx_ch;
    int sig_rx_valid;
    int sig_rx_ch;

    uint64_t next_rx_tick;

    void init_term();

public:

    bool handle_tx(Driver &drv);
    bool handle_rx(Driver &drv);

    UartModel(Driver &drv, const std::string &name);
};

}

#endif
