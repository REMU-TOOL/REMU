#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h> 

#include "control.h"
#include "emulator.h"
#include "physmap.h"
#include "platform.h"

uint32_t emu_checkpoint_size;

static uint32_t read_emu_csr(int offset) {
    return *((volatile uint32_t *)reg_map_base + (offset >> 2));
}

static void write_emu_csr(int offset, uint32_t value) {
    *((volatile uint32_t *)reg_map_base + (offset >> 2)) = value;
}

void emu_ctrl_init() {
    emu_checkpoint_size = read_emu_csr(EMU_CKPT_SIZE);
}

int emu_is_running() {
    return !(read_emu_csr(EMU_STAT) & EMU_STAT_HALT);
}

int emu_is_step_trig() {
    return (read_emu_csr(EMU_STAT) & EMU_STAT_STEP_TRIG) != 0;
}

uint32_t emu_trig_stat() {
    return read_emu_csr(EMU_TRIG_STAT);
}

void emu_halt(int halt) {
    uint32_t stat = read_emu_csr(EMU_STAT);
    if (halt)
        stat |= EMU_STAT_HALT;
    else
        stat &= ~EMU_STAT_HALT;
    write_emu_csr(EMU_STAT, stat);
}

void emu_reset(int reset) {
    uint32_t stat = read_emu_csr(EMU_STAT);
    if (reset)
        stat |= EMU_STAT_DUT_RESET;
    else
        stat &= ~EMU_STAT_DUT_RESET;
    write_emu_csr(EMU_STAT, stat);
}

uint64_t emu_read_cycle() {
    return (uint64_t)read_emu_csr(EMU_CYCLE_HI) << 32 | read_emu_csr(EMU_CYCLE_LO);
}

void emu_write_cycle(uint64_t cycle) {
    write_emu_csr(EMU_CYCLE_LO, (uint32_t)(cycle));
    write_emu_csr(EMU_CYCLE_HI, (uint32_t)(cycle >> 32));
}

void emu_step_for(uint32_t duration) {
    write_emu_csr(EMU_STEP, duration);
    emu_halt(0);
    while (!(read_emu_csr(EMU_STAT) & EMU_STAT_HALT));
}

void emu_init_reset(uint32_t duration) {
    emu_halt(1);
    emu_write_cycle(0);
    emu_reset(1);
    emu_step_for(duration);
    emu_reset(0);
}

static void emu_dma_transfer(uint64_t dma_addr, int scan_in) {
    uint32_t ctrl = EMU_DMA_CTRL_START;
    if (scan_in)
        ctrl |= EMU_DMA_CTRL_DIRECTION;
    write_emu_csr(EMU_DMA_ADDR_LO, (uint32_t)(dma_addr));
    write_emu_csr(EMU_DMA_ADDR_HI, (uint32_t)(dma_addr >> 32));
    write_emu_csr(EMU_DMA_CTRL, ctrl);
    while (read_emu_csr(EMU_DMA_STAT) & EMU_DMA_STAT_RUNNING);
}

int emu_load_checkpoint(char *file) {
    int ret = 0;
    void *map = NULL;
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    int fd = open(file, O_RDONLY);
    if (fd < 0) {
        perror("failed to open checkpoint file");
        ret = errno;
        goto cleanup;
    }

    map = mmap(NULL, emu_checkpoint_size, PROT_READ, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("failed to map checkpoint file");
        ret = errno;
        map = NULL;
        goto cleanup;
    }

    memcpy(dma_buf, map, emu_checkpoint_size);
    emu_dma_transfer(dma_addr, 1);

cleanup:
    if (map) munmap(map, emu_checkpoint_size);
    if (fd > 0) close(fd);
    return ret;
}

int emu_save_checkpoint(char *file) {
    int ret = 0;
    void *map = NULL;
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    int fd = open(file, O_RDWR | O_CREAT, (mode_t)0644);
    if (fd < 0) {
        perror("failed to open checkpoint file");
        ret = errno;
        goto cleanup;
    }

    ftruncate(fd, emu_checkpoint_size);

    map = mmap(NULL, emu_checkpoint_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("failed to map checkpoint file");
        ret = errno;
        map = NULL;
        goto cleanup;
    }

    emu_dma_transfer(dma_addr, 0);
    memcpy(map, dma_buf, emu_checkpoint_size);
    msync(map, emu_checkpoint_size, MS_SYNC);

cleanup:
    if (map) munmap(map, emu_checkpoint_size);
    if (fd > 0) close(fd);
    return ret;
}

void emu_load_checkpoint_binary(void *data) {
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    memcpy(dma_buf, data, emu_checkpoint_size);
    emu_dma_transfer(dma_addr, 1);
}

void emu_save_checkpoint_binary(void *data) {
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    emu_dma_transfer(dma_addr, 0);
    memcpy(data, dma_buf, emu_checkpoint_size);
}
