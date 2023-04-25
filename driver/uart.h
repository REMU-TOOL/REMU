#ifndef _REMU_UART_H_
#define _REMU_UART_H_

#include "driver.h"
namespace REMU {

class UartModel : public EmuModel
{
    int sig_rx_valid;
    int sig_rx_ch;

    // serializable data begin

    bool rx_ready;

    // serializable data end

    void init_term();

public:

    virtual void save(std::ostream &) const override;
    virtual void load(std::istream &) override;

    virtual bool handle_realtime_callback(Driver &) override;
    virtual bool handle_tick_callback(Driver &, uint64_t) override;

    UartModel(Driver &driver, const std::string &name);
};

}

#endif
