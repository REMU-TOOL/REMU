#include "vpi_utils.h"

using namespace REMU;

PLI_INT32 VPICallback::vpi_cb_routine(p_cb_data cb_data)
{
    auto this_ = reinterpret_cast<VPICallback*>(cb_data->user_data);
    return this_->callback();
}

void VPICallback::register_callback(uint64_t time, PLI_INT32 reason)
{
    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    cb_time.high = (uint32_t)(time >> 32);
    cb_time.low  = (uint32_t)time;

    s_cb_data cb_data;
    cb_data.reason = reason;
    cb_data.obj = 0;
    cb_data.time = &cb_time;
    cb_data.cb_rtn = vpi_cb_routine;
    cb_data.user_data = reinterpret_cast<PLI_BYTE8 *>(this);
    vpi_register_cb(&cb_data);
}
