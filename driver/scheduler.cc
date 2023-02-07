#include "scheduler.h"

#include "uma_devmem.h"
#include "uma_cosim.h"

using namespace REMU;

int Scheduler::main()
{
    // test
    printf("driver main\n");
    int rst_handle = drv.lookup_signal({"rst"});

    printf("tick count: %ld\n", drv.get_tick_count());

    drv.set_signal(rst_handle, BitVector(1, 1));
    drv.set_step_count(10);
    drv.set_mode(Driver::Mode::RUN);
    while (drv.get_mode() != Driver::Mode::PAUSE)
        Driver::sleep(100);

    printf("tick count: %ld\n", drv.get_tick_count());

    drv.set_signal(rst_handle, BitVector(1, 0));
    drv.set_step_count(5000);
    drv.set_mode(Driver::Mode::RUN);
    while (drv.get_mode() != Driver::Mode::PAUSE)
        Driver::sleep(100);

    printf("tick count: %ld\n", drv.get_tick_count());

    return 0;
}
