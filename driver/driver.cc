#include "driver.h"

#include "uma_devmem.h"
#include "uma_cosim.h"

using namespace REMU;

int Driver::main()
{
    // test
    printf("driver main\n");
    printf("mode: %s\n", HAL::mode_str[hal.get_mode()]);
    printf("tick count: %ld\n", hal.get_tick_count());
    uint32_t value = 1;
    hal.set_signal_value(0x2000, 1, &value);
    hal.set_step_count(10);
    hal.set_mode(HAL::Mode::RUN);
    HAL::sleep(100);
    printf("mode: %s\n", HAL::mode_str[hal.get_mode()]);
    printf("tick count: %ld\n", hal.get_tick_count());
    value = 0;
    hal.set_signal_value(0x2000, 1, &value);
    hal.set_step_count(100);
    hal.set_mode(HAL::Mode::RUN);
    HAL::sleep(100);
    printf("mode: %s\n", HAL::mode_str[hal.get_mode()]);
    printf("tick count: %ld\n", hal.get_tick_count());

    return 0;
}
