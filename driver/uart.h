#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include "driver.h"

namespace REMU {

class UartHandler;

class UartCallback : public Callback
{
    UartHandler &handler;

public:

    virtual void callback(Driver &) const override;

    UartCallback(UartHandler &handler) : handler(handler) {}
};

class UartHandler
{
    Driver &drv;
    UartCallback callback;

    int trig_tx_valid;
    int sig_tx_ch;
    int sig_rx_valid;
    int sig_rx_ch;

    uint64_t next_rx_tick;

    void init_term();

public:

    void handle_tx();
    void handle_rx();

    UartHandler(Driver &drv, const std::string &name);
    ~UartHandler();
};

}

#endif
