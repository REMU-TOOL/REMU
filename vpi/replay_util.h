#ifndef _REPLAY_UTIL_H_
#define _REPLAY_REPLAY_UTIL_H__H_

#include <vector>

#include <vpi_user.h>

inline std::vector<vpiHandle> tf_get_args(vpiHandle callh) {
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
    std::vector<vpiHandle> args;
    while (vpiHandle arg = vpi_scan(argv))
        args.push_back(arg);
    return args;
}

inline bool get_value_as_bool(vpiHandle obj) {
    s_vpi_value value;
    value.format = vpiScalarVal;

    vpi_get_value(obj, &value);

    return value.value.scalar == vpi1;
}

template <typename T>
inline T get_value_as(vpiHandle obj) {
    int size = vpi_get(vpiSize, obj);
    int count = (size + 31) / 32;

    s_vpi_value value;
    value.format = vpiVectorVal;

    vpi_get_value(obj, &value);

    T res = 0;
    for (int i = 0; i < count; i++) {
        T chunk = value.value.vector[i].aval & ~value.value.vector[i].bval;
        res |= chunk << (i * 32);
    }

    return res;
}

inline void set_value(vpiHandle obj, bool val) {
    s_vpi_value value;
    value.format = vpiScalarVal;
    value.value.scalar = val ? vpi1 : vpi0;

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

template <typename T>
inline void set_value(vpiHandle obj, T val) {
    uint64_t data = val;

    s_vpi_vecval vecval[2];
    for (int i = 0; i < 2; i++) {
        vecval[i].aval = data;
        vecval[i].bval = 0;
        data >>= 32;
    }

    s_vpi_value value;
    value.format = vpiVectorVal;
    value.value.vector = vecval;

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

#endif // #ifndef _REPLAY_UTIL_H_
