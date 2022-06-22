#include "vpi_loader.h"
#include "replay_util.h"

#include <algorithm>

using namespace Replay;

// https://stackoverflow.com/questions/1392059/algorithm-to-generate-bit-mask
template <typename R>
static constexpr R bitmask(unsigned int const onecount)
{
    return static_cast<R>(-(onecount != 0))
        & (static_cast<R>(-1) >> ((sizeof(R) * 8) - onecount));
}

namespace {

void vpi_load_value(vpiHandle obj, uint64_t data, int width, int offset) {
#if 0
    vpi_printf("%s[%d:%d] = %lx\n",
        vpi_get_str(vpiFullName, obj),
        width + offset - 1,
        offset,
        data & bitmask<uint64_t>(width)
    );
#endif

    int size = vpi_get(vpiSize, obj);

    s_vpi_value value;
    value.format = vpiVectorVal;
    vpi_get_value(obj, &value);

    for (int i = 0; i < size; i += 32) {
        auto &aval = value.value.vector[i/32].aval;
        auto &bval = value.value.vector[i/32].bval;
        int o = std::max(std::min(offset - i, 32), 0);
        int w = std::max(std::min(32 - o, offset + width - i), 0);
        int mask = bitmask<int>(w) << o;
        aval = ((data >> i) & mask) | (aval & ~mask);
        bval = bval & ~mask;
    }

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

}; // namespace

void VPILoader::set_ff_value(std::string name, uint64_t data, int width, int offset) {
    if (!name.empty()) {
        vpiHandle obj;
        obj = vpi_handle_by_name(name.c_str(), 0);
        if (obj == 0) {
            vpi_printf("WARNING: %s cannot be referenced\n", name.c_str());
            return;
        }

        vpi_load_value(obj, data, width, offset);
    }
}

void VPILoader::set_mem_value(std::string name, int index, uint64_t data, int width, int offset) {
    vpiHandle obj = vpi_handle_by_name(name.c_str(), 0);
    if (obj == 0) {
        vpi_printf("WARNING: %s cannot be referenced\n", name.c_str());
        return;
    }

    vpiHandle word = vpi_handle_by_index(obj, index);
    if (word == 0) {
        vpi_printf("WARNING: %s[%d] cannot be referenced\n", name.c_str(), index);
        return;
    }

    vpi_load_value(word, data, width, offset);
}
