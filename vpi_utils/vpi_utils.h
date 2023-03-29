#ifndef _VPI_UTILS_H_
#define _VPI_UTILS_H_

#include <type_traits>
#include <functional>
#include <algorithm>

#include <vpi_user.h>
#include "bitvector.h"

namespace REMU {

inline std::vector<std::string> vpiGetFullPath(vpiHandle obj)
{
    std::vector<std::string> res;
    do {
        res.push_back(vpi_get_str(vpiName, obj));
        obj = vpi_handle(vpiScope, obj);
    } while (obj != 0);
    std::reverse(res.begin(), res.end());
    return res;
}

inline std::vector<vpiHandle> vpiGetTfArgs(vpiHandle callh) {
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
    std::vector<vpiHandle> args;
    while (vpiHandle arg = vpi_scan(argv))
        args.push_back(arg);
    return args;
}

template<typename T>
inline T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_integral_v<T>>* = 0)
{
    int size = vpi_get(vpiSize, obj);
    int count = (size + 31) / 32;

    s_vpi_value value;
    value.format = vpiVectorVal;

    vpi_get_value(obj, &value);

    T res = 0;
    for (int i = 0; i < count; i++) {
        uint32_t chunk = value.value.vector[i].aval & ~value.value.vector[i].bval;
        res |= T(chunk) << (i * 32);
    }

    return res;
}

template<>
inline bool vpiGetValue(vpiHandle obj, void*)
{
    s_vpi_value value;
    value.format = vpiScalarVal;

    vpi_get_value(obj, &value);

    return value.value.scalar == vpi1;
}

template<typename T>
inline T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_same_v<T, BitVector>>* = 0)
{
    int size = vpi_get(vpiSize, obj);
    int count = (size + 31) / 32;

    s_vpi_value value;
    value.format = vpiVectorVal;

    vpi_get_value(obj, &value);

    REMU::BitVector res(size);
    for (int i = 0; i < count; i++) {
        int chunk = value.value.vector[i].aval & ~value.value.vector[i].bval;
        res.setValue(i * 32, size < 32 ? size : 32, chunk);
        size -= 32;
    }

    return res;
}

template<typename T>
inline T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_same_v<T, std::string>>* = 0)
{
    s_vpi_value value;
    value.format = vpiStringVal;

    vpi_get_value(obj, &value);

    std::string res(value.value.str);
    return res;
}

template <typename T>
inline void vpiSetValue(vpiHandle obj, T val, PLI_INT32 flags = vpiNoDelay, uint64_t time = 0, std::enable_if_t<std::is_integral_v<T>>* = 0)
{
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

    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    cb_time.high = (uint32_t)(time >> 32);
    cb_time.low  = (uint32_t)time;
    vpi_put_value(obj, &value, &cb_time, flags);
}

template<>
inline void vpiSetValue(vpiHandle obj, bool val, PLI_INT32 flags, uint64_t time, void*)
{
    s_vpi_value value;
    value.format = vpiScalarVal;
    value.value.scalar = val ? vpi1 : vpi0;

    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    cb_time.high = (uint32_t)(time >> 32);
    cb_time.low  = (uint32_t)time;
    vpi_put_value(obj, &value, &cb_time, flags);
}

inline void vpiSetValue(vpiHandle obj, const REMU::BitVector &val, PLI_INT32 flags = vpiNoDelay, uint64_t time = 0)
{
    int size = vpi_get(vpiSize, obj);
    int count = (size + 31) / 32;

    s_vpi_vecval vecval[count];
    for (int i = 0; i < count; i++) {
        vecval[i].aval = val.getValue(i * 32, size < 32 ? size : 32);
        vecval[i].bval = 0;
        size -= 32;
    }

    s_vpi_value value;
    value.format = vpiVectorVal;
    value.value.vector = vecval;

    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    cb_time.high = (uint32_t)(time >> 32);
    cb_time.low  = (uint32_t)time;
    vpi_put_value(obj, &value, &cb_time, flags);
}

inline uint64_t vpiGetSimTime()
{
    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    vpi_get_time(0, &cb_time);
    uint64_t timeval = ((uint64_t)cb_time.high << 32) | cb_time.low;
    return timeval;
}

class VPICallback
{
    std::function<int(uint64_t)> callback;
    s_vpi_time cb_time;
    s_vpi_value cb_value;

    static PLI_INT32 callback_routine(p_cb_data cb_data);

public:

    void register_callback(uint64_t time, PLI_INT32 reason, vpiHandle obj = 0);

    VPICallback(std::function<int(uint64_t)> callback) : callback(callback) {}
};

}

#endif
