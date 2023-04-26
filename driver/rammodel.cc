#include "rammodel.h"
#include "driver.h"

using namespace REMU;

const std::vector<std::string> RamModel::type_names = {
    "fixed",
};

int RamModelFixed::get_r_delay()
{
    return driver.get_signal_value(sig_r_delay);
}

int RamModelFixed::get_w_delay()
{
    return driver.get_signal_value(sig_w_delay);
}

bool RamModelFixed::set_r_delay(int delay)
{
    if (delay <= 0) {
        fprintf(stderr, "[RamModelFixed] WARNING: set_r_delay(%d) is ignored; delay must be greater than 0.\n",
            delay);
        return false;
    }

    fprintf(stderr, "[RamModelFixed] INFO: setting r_delay to %d\n", delay);
    driver.set_signal_value(sig_r_delay, BitVector(16, delay));
    return true;
}

bool RamModelFixed::set_w_delay(int delay)
{
    if (delay <= 0) {
        fprintf(stderr, "[RamModelFixed] WARNING: set_w_delay(%d) is ignored; delay must be greater than 0.\n",
            delay);
        return false;
    }

    fprintf(stderr, "[RamModelFixed] INFO: setting w_delay to %d\n", delay);
    driver.set_signal_value(sig_w_delay, BitVector(16, delay));
    return true;
}

RamModelFixed::RamModelFixed(Driver &driver, const std::string &name) : driver(driver), name(name)
{
    sig_r_delay = driver.lookup_signal(name + ".frontend.timing_model.\\fixed.inst .cfg.r_delay");
    sig_w_delay = driver.lookup_signal(name + ".frontend.timing_model.\\fixed.inst .cfg.w_delay");
}
