#include "driver.h"

#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <fstream>

#include "emu_utils.h"
#include "regdef.h"

using namespace REMU;

void Driver::init_axi()
{
    for (auto &info : sysinfo.axi) {
        om_axi.add({
            .name           = flatten_name(info.name),
            .size           = info.size,
            .reg_offset     = info.reg_offset,
            .assigned_offset  = 0,
            .assigned_size  = 0,
        });
    }

    // Allocate memory regions, the largest size first

    std::vector<AXIObject*> sort_list;
    for (auto &axi : om_axi)
        sort_list.push_back(&axi);

    std::sort(sort_list.begin(), sort_list.end(),
        [](AXIObject *a, AXIObject *b) { return a->size > b->size; });

    uint64_t dmabase = mem->dmabase();
    uint64_t alloc_size = 0;
    for (auto p : sort_list) {
        p->assigned_size = 1 << clog2(p->size); // power of 2
        p->assigned_offset = alloc_size;
        alloc_size += p->assigned_size;
        fprintf(stderr, "[REMU] INFO: Allocated memory (offset 0x%08lx - 0x%08lx) for AXI port \"%s\"\n",
            dmabase + p->assigned_offset,
            dmabase + p->assigned_offset + p->assigned_size,
            p->name.c_str());
    }

    if (alloc_size > mem->size()) {
        fprintf(stderr, "[REMU] ERROR: this platform does not have enough device memory (0x%lx actual, 0x%lx required)\n",
            mem->size(), alloc_size);
        throw std::runtime_error("insufficient device memory");
    }

    // Configure AXI remap

    for (auto &axi : om_axi) {
        uint64_t base = dmabase + axi.assigned_offset;
        uint64_t mask = axi.assigned_size - 1;
        reg->write(axi.reg_offset + 0x0, base >>  0);
        reg->write(axi.reg_offset + 0x4, base >> 32);
        reg->write(axi.reg_offset + 0x8, mask >>  0);
        reg->write(axi.reg_offset + 0xc, mask >> 32);
    }

    // Process memory initialization

    for (auto &kv : options.init_axi_mem) {
        int index = om_axi.lookup(kv.first);
        if (index < 0) {
            fprintf(stderr, "[REMU] WARNING: AXI port \"%s\" specified by --init-axi-mem is not found\n",
                kv.first.c_str());
            continue;
        }
        auto &axi = om_axi.get(index);
        fprintf(stderr, "[REMU] INFO: Initializing memory for AXI port \"%s\" with file \"%s\"\n",
            kv.first.c_str(), kv.second.c_str());
        std::ifstream f(kv.second, std::ios::binary);
        if (f.fail()) {
            fprintf(stderr, "[REMU] ERROR: Can't open file `%s': %s\n", kv.second.c_str(), strerror(errno));
            continue;
        }
        mem->copy_from_stream(axi.assigned_offset, axi.assigned_size, f);
    }
}
