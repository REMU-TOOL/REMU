#ifndef _VPI_UTILS_H_
#define _VPI_UTILS_H_

#include <type_traits>

#include <vpi_user.h>
#include "bitvector.h"

namespace REMU {

std::vector<vpiHandle> vpiGetTfArgs(vpiHandle callh) {
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
    std::vector<vpiHandle> args;
    while (vpiHandle arg = vpi_scan(argv))
        args.push_back(arg);
    return args;
}

template<typename T>
T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_integral_v<T>>* = 0)
{
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

template<>
bool vpiGetValue(vpiHandle obj, void*)
{
    s_vpi_value value;
    value.format = vpiScalarVal;

    vpi_get_value(obj, &value);

    return value.value.scalar == vpi1;
}

template<typename T>
T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_same_v<T, BitVector>>* = 0)
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
T vpiGetValue(vpiHandle obj, std::enable_if_t<std::is_same_v<T, std::string>>* = 0)
{
    s_vpi_value value;
    value.format = vpiStringVal;

    vpi_get_value(obj, &value);

    std::string res(value.value.str);
    return res;
}

template <typename T>
void vpiSetValue(vpiHandle obj, T val, std::enable_if_t<std::is_integral_v<T>>* = 0)
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

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

template<>
void vpiSetValue(vpiHandle obj, bool val, void*)
{
    s_vpi_value value;
    value.format = vpiScalarVal;
    value.value.scalar = val ? vpi1 : vpi0;

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

void vpiSetValue(vpiHandle obj, const REMU::BitVector &val)
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

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

}

#endif
