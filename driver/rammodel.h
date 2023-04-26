#ifndef _REMU_RAMMODEL_H_
#define _REMU_RAMMODEL_H_

#include <string>
#include <vector>

namespace REMU {

class Driver;

enum RamModelType
{
    FIXED,
};

class RamModel
{
public:
    virtual RamModelType get_type() const = 0;
    virtual ~RamModel() {}
    static const std::vector<std::string> type_names;
};

class RamModelFixed : public RamModel
{
    Driver &driver;
    std::string name;

    int sig_r_delay;
    int sig_w_delay;

public:

    virtual RamModelType get_type() const override { return FIXED; }

    int get_r_delay();
    int get_w_delay();

    bool set_r_delay(int delay);
    bool set_w_delay(int delay);

    RamModelFixed(Driver &driver, const std::string &name);
};

}

#endif
