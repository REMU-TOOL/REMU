#include "cosim.h"
#include "vpi_utils.h"

#include <memory>

using namespace REMU;

std::unique_ptr<CosimServer> server;

// function integer $cosim_new(input [63:0] mem_size)
int cosim_new_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto mem_size = vpiGetValue<uint64_t>(args[0]);
    if (!server)
        server = std::make_unique<CosimServer>(mem_size);

    vpiSetValue(callh, 0);
    return 0;
}

// function integer $cosim_mem_read(input [63:0] addr, output [width-1:0] data)
int cosim_mem_read_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto addr = vpiGetValue<uint64_t>(args[0]);
    if (addr >= server->mem_size()) {
        vpi_printf("%s: address 0x%lx out of range\n", __func__, addr);
        vpiSetValue(callh, -1);
        return 0;
    }

    int width = vpi_get(vpiSize, args[1]);
    switch (width) {
        case 64:    vpiSetValue(args[1], server->mem_read<uint64_t>(addr));     break;
        case 32:    vpiSetValue(args[1], server->mem_read<uint32_t>(addr));     break;
        case 16:    vpiSetValue(args[1], server->mem_read<uint16_t>(addr));     break;
        case 8:     vpiSetValue(args[1], server->mem_read<uint8_t>(addr));      break;
        default:    vpiSetValue(callh, -1); return 0;
    }

    vpiSetValue(callh, 0);
    return 0;
}

// function integer $cosim_mem_write(input [63:0] addr, input [width-1:0] data)
int cosim_mem_write_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto addr = vpiGetValue<uint64_t>(args[0]);
    if (addr >= server->mem_size()) {
        vpi_printf("%s: address 0x%lx out of range\n", __func__, addr);
        vpiSetValue(callh, -1);
        return 0;
    }

    int width = vpi_get(vpiSize, args[1]);
    switch (width) {
        case 64:    server->mem_write(addr, vpiGetValue<uint64_t>(args[1]));    break;
        case 32:    server->mem_write(addr, vpiGetValue<uint32_t>(args[1]));    break;
        case 16:    server->mem_write(addr, vpiGetValue<uint16_t>(args[1]));    break;
        case 8:     server->mem_write(addr, vpiGetValue<uint8_t>(args[1]));     break;
        default:    vpiSetValue(callh, -1); return 0;
    }

    vpiSetValue(callh, 0);
    return 0;
}

// function integer $cosim_poll_req(
//    output integer write,
//    output [63:0] addr,
//    output [31:0] value)
int cosim_poll_req_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 3) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    CosimMsgReq req;
    if (server->poll_req(req)) {
        vpiSetValue(args[0], req.type == RegWrite);
        vpiSetValue(args[1], req.addr);
        vpiSetValue(args[2], req.value);

        vpiSetValue(callh, 1);
        return 0;
    }

    vpiSetValue(callh, 0);
    return 0;
}

// function integer $cosim_send_resp(
//    output integer write,
//    output [31:0] value)
int cosim_send_resp_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    CosimMsgResp resp = {
        .type   = vpiGetValue<int>(args[0]) ? RegWrite : RegRead,
        .value  = vpiGetValue<uint32_t>(args[1]),
    };
    server->send_resp(resp);

    vpiSetValue(callh, 0);
    return 0;
}

void cosim_vpi_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$cosim_new";
    tf_data.calltf      = cosim_new_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$cosim_mem_read";
    tf_data.calltf      = cosim_mem_read_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$cosim_mem_write";
    tf_data.calltf      = cosim_mem_write_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$cosim_poll_req";
    tf_data.calltf      = cosim_poll_req_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$cosim_send_resp";
    tf_data.calltf      = cosim_send_resp_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
    cosim_vpi_register,
    0
};
