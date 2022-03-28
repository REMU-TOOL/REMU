#include <vpi_user.h>

#include "loader.h"

static void reconstruct_main() {

}

void (*vlog_startup_routines[])() = {
    reconstruct_main,
    0
};
