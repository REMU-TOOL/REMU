#ifndef __PHYSMAP_H__
#define __PHYSMAP_H__

extern void *mem_map_base, *reg_map_base;

int init_map();
void fini_map();

#endif
