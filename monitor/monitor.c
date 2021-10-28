#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <alloca.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h> 

#include "emulator.h"
#include "platform.h"

#define SHELL_BUFSIZE 256

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

uint32_t read_emu_csr(int offset) {
    return *((volatile uint32_t *)reg_map_base + (offset >> 2));
}

void write_emu_csr(int offset, uint32_t value) {
    *((volatile uint32_t *)reg_map_base + (offset >> 2)) = value;
}

int emu_is_running() {
    return !(read_emu_csr(EMU_STAT) & EMU_STAT_HALT);
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

void emu_dma_transfer(uint64_t dma_addr, int scan_in) {
    uint32_t ctrl = EMU_DMA_CTRL_START;
    if (scan_in)
        ctrl |= EMU_DMA_CTRL_DIRECTION;
    write_emu_csr(EMU_DMA_ADDR_LO, (uint32_t)(dma_addr));
    write_emu_csr(EMU_DMA_ADDR_HI, (uint32_t)(dma_addr >> 32));
    write_emu_csr(EMU_DMA_CTRL, ctrl);
    while (read_emu_csr(EMU_DMA_STAT) & EMU_DMA_STAT_RUNNING);
}

uint32_t emu_checkpoint_size() {
    return read_emu_csr(EMU_CKPT_SIZE);
}

int emu_load_checkpoint(char *file) {
    int ret = 0;
    void *map = NULL;
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    size_t size = emu_checkpoint_size();
    int fd = open(file, O_RDONLY);
    if (fd < 0) {
        perror("failed to open checkpoint file");
        ret = errno;
        goto cleanup;
    }

    map = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("failed to map checkpoint file");
        ret = errno;
        map = NULL;
        goto cleanup;
    }

    memcpy(dma_buf, map, size);
    emu_dma_transfer(dma_addr, 1);

cleanup:
    if (map) munmap(map, size);
    if (fd > 0) close(fd);
    return ret;
}

int emu_save_checkpoint(char *file) {
    int ret = 0;
    void *map = NULL;
    uint64_t dma_addr = PLAT_MEM_BASE;
    void *dma_buf = mem_map_base;
    size_t size = emu_checkpoint_size();
    int fd = open(file, O_RDWR | O_CREAT, (mode_t)0644);
    if (fd < 0) {
        perror("failed to open checkpoint file");
        ret = errno;
        goto cleanup;
    }

    ftruncate(fd, size);

    map = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("failed to map checkpoint file");
        ret = errno;
        map = NULL;
        goto cleanup;
    }

    emu_dma_transfer(dma_addr, 0);
    memcpy(map, dma_buf, size);
    msync(map, size, MS_SYNC);

cleanup:
    if (map) munmap(map, size);
    if (fd > 0) close(fd);
    return ret;
}

int parse_num(const char *str, unsigned long *result) {
	unsigned long res = 0, newres;
	unsigned int radix = 10, len = strlen(str);
	unsigned char c;

	if (len > 2 && str[0] == '0' && str[1] == 'x') {
		str += 2;
		radix = 16;
	}

	while (c = *str++) {
		if (c >= '0' && c <= '9')
			c -= '0';
		else if (radix == 16) {
			if (c >= 'A' && c <= 'F')
				c -= 'A' - 10;
			else if (c >= 'a' && c <= 'f')
				c -= 'a' - 10;
			else
				return 1;
		}
		else
			return 1;

		newres = res * radix + c;
		if (newres < res)
			return 2;

		res = newres;
	}

	*result = res;
	return 0;
}

char *tokenize(char *next, int dry_run) {
    int in_quote = 0, prev_backslash = 0, leading_spaces = 1, trailing_spaces = 0;
    char *read = next, *write = next;
    if (*next == '\0' || *next == '\n') {
        return NULL;
    }
    for (;;) {
        char c = *read++;
        if (c == '\0' || c == '\n') {
            if (!dry_run) *write++ = '\0';
            read--;
            break;
        }
        if (c == ' ') {
            if (leading_spaces || trailing_spaces)
                continue;
            if (in_quote || prev_backslash) {
                if (!dry_run) *write++ = c;
                prev_backslash = 0;
                continue;
            }
            if (!dry_run) *write++ = '\0';
            trailing_spaces = 1;
            continue;
        }
        leading_spaces = 0;
        if (trailing_spaces) {
            read--;
            break;
        }
        switch (c) {
            case '\\':
                if (prev_backslash) {
                    if (!dry_run) *write++ = c;
                    prev_backslash = 0;
                }
                else {
                    prev_backslash = 1;
                }
                break;
            case '"':
                if (prev_backslash) {
                    if (!dry_run) *write++ = c;
                    prev_backslash = 0;
                }
                else {
                    in_quote = !in_quote;
                }
                break;
            default:
                if (!dry_run) *write++ = c;
                break;
        }
    }
    return read;
}

void show_help() {
    printf(
        "Available commands:\n"
        "    help\n"
        "        Show this message.\n"
        "    state\n"
        "        Print emulator state (running/stopped).\n"
        "    cycle [<new_cycle>]\n"
        "        Set cycle count to <new_cycle> if specified. Otherwise print current cycle count.\n"
        "    reset <duration>\n"
        "        Perform initial reset sequence where reset is held for <duration> cycles.\n"
        "        Note this command also resets cycle count.\n"
        "    run [<duration>]\n"
        "        Continue emulation execution. Run for <duration> cycles and stop if specified.\n"
        "    stop\n"
        "        Pause emulation execution.\n"
        "    step\n"
        "        Synonym for \"run 1\".\n"
        "    load <checkpoint>\n"
        "        load checkpoint from file <checkpoint>.\n"
        "    save <checkpoint>\n"
        "        save checkpoint to file <checkpoint>.\n"
        "\n"
    );
}

void run_command(int argc, char **argv) {
    if (argc == 0 || !strcmp(argv[0], "help")) {
        show_help();
    }
    else if (!strcmp(argv[0], "state")) {
        printf("%s\n", emu_is_running() ? "running" : "stopped");
    }
    else if (!strcmp(argv[0], "cycle")) {
        if (argc >= 2) {
            unsigned long cycle;
            if (parse_num(argv[1], &cycle)) {
                fprintf(stderr, "ERROR: unrecognized number %s\n", argv[1]);
                return;
            }
            emu_write_cycle(cycle);
        }
        else {
            printf("%lu\n", emu_read_cycle());
        }
    }
    else if (!strcmp(argv[0], "reset")) {
        unsigned long duration;
        if (argc < 2) {
            fprintf(stderr, "ERROR: duration required\n");
            return;
        }
        if (parse_num(argv[1], &duration)) {
            fprintf(stderr, "ERROR: unrecognized number %s\n", argv[1]);
            return;
        }
        fprintf(stderr, "Step reset for %u cycles ...\n", (uint32_t)duration);
        emu_init_reset((uint32_t)duration);
        fprintf(stderr, "Cycle count is now %lu\n", emu_read_cycle());
    }
    else if (!strcmp(argv[0], "run")) {
        if (argc >= 2) {
            unsigned long duration;
            if (parse_num(argv[1], &duration)) {
                fprintf(stderr, "ERROR: unrecognized number %s\n", argv[1]);
                return;
            }
            fprintf(stderr, "Continue for %u cycles ...\n", (uint32_t)duration);
            emu_step_for(duration);
            fprintf(stderr, "Cycle count is now %lu\n", emu_read_cycle());
        }
        else {
            fprintf(stderr, "Continue execution ...\n");
            emu_halt(0);
        }
    }
    else if (!strcmp(argv[0], "stop")) {
        fprintf(stderr, "Pause execution ...\n");
        emu_halt(1);
    }
    else if (!strcmp(argv[0], "step")) {
        fprintf(stderr, "Step for 1 cycle ...\n");
        emu_step_for(1);
        fprintf(stderr, "Cycle count is now %lu\n", emu_read_cycle());
    }
    else if (!strcmp(argv[0], "load")) {
        if (argc < 2) {
            fprintf(stderr, "ERROR: checkpoint file name required\n");
            return;
        }
        fprintf(stderr, "Load checkpoint from file %s ...\n", argv[1]);
        printf("%d\n", emu_load_checkpoint(argv[1]));
    }
    else if (!strcmp(argv[0], "save")) {
        if (argc < 2) {
            fprintf(stderr, "ERROR: checkpoint file name required\n");
            return;
        }
        fprintf(stderr, "Save checkpoint to file %s ...\n", argv[1]);
        printf("%d\n", emu_save_checkpoint(argv[1]));
    }
    else {
        fprintf(stderr, "Unrecognized command %s. Enter 'help' for available commands.\n", argv[0]);
    }
}

void shell() {
    char buf[SHELL_BUFSIZE];
    while ((fprintf(stderr, "> "), fgets(buf, SHELL_BUFSIZE, stdin))) {
        int argc = 0;
        char **argv, *token, *next;
        next = buf;
        while (next = tokenize(next, 1)) {
            argc++;
        }
        argv = alloca(argc * sizeof(char *));
        argc = 0;
        token = next = buf;
        while (next = tokenize(next, 0)) {
            argv[argc++] = token;
            token = next;
        }
        if (strlen(argv[argc-1]) == 0) argc--;
        run_command(argc, argv);
    }
}

int main() {
    int res;

    setvbuf(stdout, NULL, _IOLBF, 0);

    res = init_map();
    if (res)
        return res;

    shell();

    fini_map();
    return 0;
}
