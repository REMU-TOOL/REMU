#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h> 

#include "platform.h"
#include "physmap.h"

void *mem_map_base, *reg_map_base;

int init_map() {
    int ret = 0;
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem failed");
        ret = errno;
        goto cleanup;
    }

    mem_map_base = mmap(NULL, PLAT_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, PLAT_MEM_BASE);
    if (mem_map_base == MAP_FAILED) {
        perror("map memory region failed");
        ret = errno;
        mem_map_base = NULL;
        goto cleanup;
    }

    reg_map_base = mmap(NULL, PLAT_REG_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, PLAT_REG_BASE);
    if (reg_map_base == MAP_FAILED) {
        perror("map register region failed");
        ret = errno;
        munmap(mem_map_base, PLAT_MEM_SIZE);
        mem_map_base = NULL;
        reg_map_base = NULL;
        goto cleanup;
    }

cleanup:
    if (fd > 0) close(fd);
    return ret;
}

void fini_map() {
    munmap(mem_map_base, PLAT_MEM_SIZE);
    mem_map_base = NULL;
    munmap(reg_map_base, PLAT_REG_SIZE);
    reg_map_base = NULL;
}
