#ifndef __CONTROL_H__
#define __CONTROL_H__

#include <stdint.h>

extern uint32_t emu_checkpoint_size;

void emu_ctrl_init();

int emu_is_running();
void emu_halt(int halt);
void emu_reset(int reset);

uint64_t emu_read_cycle();
void emu_write_cycle(uint64_t cycle);

void emu_step_for(uint32_t duration);
void emu_init_reset(uint32_t duration);

int emu_load_checkpoint(char *file);
int emu_save_checkpoint(char *file);
void emu_load_checkpoint_binary(void *data);
void emu_save_checkpoint_binary(void *data);

#endif
