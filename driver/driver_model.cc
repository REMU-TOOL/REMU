#include "driver.h"
#include "uart.h"
#include "emu_utils.h"

using namespace REMU;

void Driver::init_model()
{
    for (auto &info : sysinfo.model) {
        auto name = flatten_name(info.name);
        if (info.type == "uart") {
            fprintf(stderr, "[REMU] INFO: Model \"%s\" recognized as UART model\n",
                name.c_str());
            models[name] = std::unique_ptr<DriverModel>(new UartModel(*this, name));
        }
        else if (info.type == "rammodel"){
            fprintf(stderr, "[REMU] INFO: Model \"%s\" recognized as RAM model\n",
                name.c_str());
        }
        else {
            fprintf(stderr, "[REMU] WARNING: Model \"%s\" of unrecognized type \"%s\" is ignored\n",
                name.c_str(), info.type.c_str());
        }
    }
}
