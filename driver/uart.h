#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include <string>
#include <termios.h>

namespace REMU {

class Driver;

class UartModel
{
    int sig_rx_toggle;
    int sig_rx_ch;

    bool term_mode;
    struct termios old_term;
    int old_fl;

    char ch_to_send;

public:

    void enter_term();
    void exit_term();

    void poll(Driver &);

    bool send(char ch);

    UartModel(Driver &driver, const std::string &name);
};

}

#endif
