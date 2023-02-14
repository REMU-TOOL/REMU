#include "vpi_utils.h"

using namespace REMU;

PLI_INT32 VPICallback::callback_routine(p_cb_data cb_data)
{
    auto this_ = reinterpret_cast<VPICallback*>(cb_data->user_data);
    uint64_t time = ((uint64_t)cb_data->time->high << 32) | cb_data->time->low;
    return this_->callback(time);
}

void VPICallback::register_callback(uint64_t time, PLI_INT32 reason, vpiHandle obj)
{
    cb_time.type = vpiSimTime;
    cb_time.high = (uint32_t)(time >> 32);
    cb_time.low  = (uint32_t)time;

    cb_value.format = vpiSuppressVal;

    s_cb_data cb_data;
    cb_data.reason = reason;
    cb_data.obj = obj;
    cb_data.time = &cb_time;
    cb_data.value = &cb_value;
    cb_data.cb_rtn = callback_routine;
    cb_data.user_data = reinterpret_cast<PLI_BYTE8 *>(this);
    vpi_register_cb(&cb_data);
}
