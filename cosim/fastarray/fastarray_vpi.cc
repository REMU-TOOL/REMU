#include "fastarray.h"
#include "vpi_utils.h"
#include <fstream>

using namespace REMU;

std::vector<FastArray> fastarray_instances;

// function integer $fastarray_new(input [63:0] width, input [63:0] depth)
int fastarray_new_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto width = vpiGetValue<uint64_t>(args[0]);
    auto depth = vpiGetValue<uint64_t>(args[1]);

    size_t index = fastarray_instances.size();
    fastarray_instances.emplace_back(width, depth);

    vpiSetValue(callh, (int)index);
    return 0;
}

// function integer $fastarray_read(input integer index, input [63:0] pos, output [width-1:0] data)
int fastarray_read_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 3) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto index = vpiGetValue<int>(args[0]);
    if (index < 0 || index >= fastarray_instances.size()) {
        vpiSetValue(callh, -1);
        return 0;
    }
    auto &inst = fastarray_instances.at(index);

    auto pos = vpiGetValue<uint64_t>(args[0]);
    if (pos < 0 || pos > inst.depth()) {
        vpiSetValue(callh, -1);
        return 0;
    }

    vpiSetValue(args[2], inst.read(pos));
    vpiSetValue(callh, 0);
    return 0;
}

// function integer $fastarray_write(input integer index, input [63:0] pos, input [width-1:0] data)
int fastarray_write_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 3) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto index = vpiGetValue<int>(args[0]);
    if (index < 0 || index >= fastarray_instances.size()) {
        vpiSetValue(callh, -1);
        return 0;
    }
    auto &inst = fastarray_instances.at(index);

    auto pos = vpiGetValue<uint64_t>(args[0]);
    if (pos < 0 || pos > inst.depth()) {
        vpiSetValue(callh, -1);
        return 0;
    }

    inst.write(pos, vpiGetValue<BitVector>(args[2]));
    vpiSetValue(callh, 0);
    return 0;
}

// function integer $fastarray_load(input integer index, input string path)
int fastarray_load_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto index = vpiGetValue<int>(args[0]);
    if (index < 0 || index >= fastarray_instances.size()) {
        vpiSetValue(callh, -1);
        return 0;
    }
    auto &inst = fastarray_instances.at(index);

    auto path = vpiGetValue<std::string>(args[1]);
    std::ifstream f(path, std::ios::binary);
    if (f.fail()) {
        vpiSetValue(callh, -1);
        return 0;
    }

    if (!inst.load(f)) {
        vpiSetValue(callh, -1);
        return 0;
    }

    vpiSetValue(callh, 0);
    return 0;
}

// function integer $fastarray_save(input integer index, input string path)
int fastarray_save_calltf(char*)
{
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    auto index = vpiGetValue<int>(args[0]);
    if (index < 0 || index >= fastarray_instances.size()) {
        vpiSetValue(callh, -1);
        return 0;
    }
    auto &inst = fastarray_instances.at(index);

    auto path = vpiGetValue<std::string>(args[1]);
    std::ofstream f(path, std::ios::binary);
    if (f.fail()) {
        vpiSetValue(callh, -1);
        return 0;
    }

    if (!inst.save(f)) {
        vpiSetValue(callh, -1);
        return 0;
    }

    vpiSetValue(callh, 0);
    return 0;
}

void fastarray_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$fastarray_new";
    tf_data.calltf      = fastarray_new_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$fastarray_read";
    tf_data.calltf      = fastarray_read_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$fastarray_write";
    tf_data.calltf      = fastarray_write_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$fastarray_load";
    tf_data.calltf      = fastarray_load_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$fastarray_save";
    tf_data.calltf      = fastarray_save_calltf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
    fastarray_register,
    0
};
