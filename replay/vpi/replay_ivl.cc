#include "replay_ivl.h"
#include "model.h"
#include "vpi_utils.h"
#include "escape.h"

#include <map>
#include <string>
#include <vector>

using namespace REMU;

void VPILoader::load()
{
    circuit.load(checkpoint);

    for (auto &it : circuit.wire) {
        vpiHandle obj = 0;
        for (auto &name : it.first) {
            std::string esc_name = Escape::escape_verilog_id(name);
            vpiHandle parent = obj;
            obj = vpi_handle_by_name(esc_name.c_str(), obj);
            if (obj == 0) {
                vpi_printf("WARNING: %s cannot be referenced (in scope %s)\n",
                    esc_name.c_str(), parent == 0 ? "<TOPLEVEL>" : vpi_get_str(vpiFullName, parent));
                break;
            }
        }
        if (obj == 0)
            continue;
        vpiSetValue(obj, it.second);
    }

    for (auto &it : circuit.ram) {
        vpiHandle obj = 0;
        for (auto &name : it.first) {
            std::string esc_name = Escape::escape_verilog_id(name);
            vpiHandle parent = obj;
            obj = vpi_handle_by_name(esc_name.c_str(), obj);
            if (obj == 0) {
                vpi_printf("WARNING: %s cannot be referenced (in scope %s)\n",
                    esc_name.c_str(), parent == 0 ? "<TOPLEVEL>" : vpi_get_str(vpiFullName, parent));
                break;
            }
        }
        if (obj == 0)
            continue;
        int depth = it.second.depth();
        int start_offset = it.second.start_offset();
        for (int i = 0; i < depth; i++) {
            int index = i + start_offset;
            vpiHandle word_obj = vpi_handle_by_index(obj, index);
            if (word_obj == 0) {
                vpi_printf("WARNING: %s[%d] cannot be referenced\n",
                    vpi_get_str(vpiFullName, obj), index);
                continue;
            }
            vpiSetValue(word_obj, it.second.get(i));
        }
    }
}

std::vector<RamModel> rammodel_list;

int rammodel_new_tf(char* user_data)
{
    auto loader = reinterpret_cast<VPILoader*>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, -1);
        return 0;
    }

    uint32_t addr_width, data_width, id_width;
    uint64_t mem_size;
    addr_width  = vpiGetValue<uint32_t>(args[0]);
    data_width  = vpiGetValue<uint32_t>(args[1]);
    id_width    = vpiGetValue<uint32_t>(args[2]);
    mem_size    = vpiGetValue<uint64_t>(args[3]);

    size_t index = rammodel_list.size();
    rammodel_list.emplace_back(addr_width, data_width, id_width, mem_size);

    vpiHandle scope = vpi_handle(vpiScope, callh);
    std::string name = vpi_get_str(vpiFullName, scope);
    vpi_printf("rammodel info: %s registered with handle %ld\n", name.c_str(), index);

    auto data_stream = loader->checkpoint.readMem(name + ".host_axi");
    if (data_stream.fail()) {
        vpi_printf("ERROR: failed to open rammodel data file\n");
        vpiSetValue(callh, -1);
        return 0;
    }
    if (!rammodel_list[index].load_data(data_stream)) {
        vpi_printf("ERROR: failed to load rammodel data from checkpoint\n");
        vpiSetValue(callh, -1);
        return 0;
    }

    auto path = vpiGetFullPath(scope);
    rammodel_list[index].load_state(loader->circuit, path);

    vpiSetValue(callh, index);
    return 0;
}

int rammodel_reset_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].reset();
    if (!res) {
        vpi_printf("%s: reset failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_a_req_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 7) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    RamModel::AChannel payload = {
        .addr    = vpiGetValue<uint64_t>(args[2]),
        .id      = vpiGetValue<uint16_t>(args[1]),
        .len     = vpiGetValue<uint8_t>(args[3]),
        .size    = vpiGetValue<uint8_t>(args[4]),
        .burst   = vpiGetValue<uint8_t>(args[5]),
        .write   = vpiGetValue<bool>(args[6])
    };

    bool res = rammodel_list[index].a_req(payload);
    if (!res) {
        vpi_printf("%s: A req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_w_req_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    RamModel::WChannel payload = {
        .data   = vpiGetValue<BitVector>(args[1]),
        .strb   = vpiGetValue<BitVector>(args[2]),
        .last   = vpiGetValue<bool>(args[3])
    };

    bool res = rammodel_list[index].w_req(payload);
    if (!res) {
        vpi_printf("%s: W req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_b_req_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    RamModel::BChannel payload = {
        .id = vpiGetValue<uint16_t>(args[1])
    };
    bool res = rammodel_list[index].b_req(payload);
    if (!res) {
        vpi_printf("%s: B req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_b_ack_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].b_ack();
    if (!res) {
        vpi_printf("%s: B ack failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_r_req_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    RamModel::RChannel payload = {
        .data   = BitVector(1),
        .id     = vpiGetValue<uint16_t>(args[1]),
        .last   = false
    };
    bool res = rammodel_list[index].r_req(payload);
    if (!res) {
        vpi_printf("%s: R req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(args[2], payload.data);
    vpiSetValue(args[3], payload.last);

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_r_ack_tf(char* user_data)
{
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    uint32_t index = vpiGetValue<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].r_ack();
    if (!res) {
        vpi_printf("%s: R ack failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

void REMU::register_tfs(REMU::VPILoader *loader)
{
    s_vpi_systf_data tf_data;
    PLI_BYTE8 *user_data = reinterpret_cast<PLI_BYTE8 *>(loader);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_new";
    tf_data.calltf      = rammodel_new_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_reset";
    tf_data.calltf      = rammodel_reset_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_a_req";
    tf_data.calltf      = rammodel_a_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_w_req";
    tf_data.calltf      = rammodel_w_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_req";
    tf_data.calltf      = rammodel_b_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_ack";
    tf_data.calltf      = rammodel_b_ack_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_req";
    tf_data.calltf      = rammodel_r_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_ack";
    tf_data.calltf      = rammodel_r_ack_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);
}

static constexpr uint64_t period = 10000;

void replay_initialize(VPILoader *loader)
{
    // loader callback

    static VPICallback loader_cb([loader](uint64_t) {
        loader->load();
        return 0;
    });
    loader_cb.register_callback(0, cbAtEndOfSimTime);

    // cycle callback
    // TODO: support multiple clocks with different frequencies

    vpiHandle cycle_h = vpi_handle_by_name("remu_replay.cycle", 0);
    if (cycle_h == 0) {
        vpi_printf("ERROR: failed to get remu_replay.cycle\n");
        vpi_control(vpiFinish);
        return;
    }

    uint64_t init_tick = loader->tick;
    static VPICallback cycle_cb([cycle_h, init_tick](uint64_t time) {
        vpiSetValue(cycle_h, init_tick + time / period);
        cycle_cb.register_callback(time + period, cbAtEndOfSimTime);
        return 0;
    });
    cycle_cb.register_callback(0, cbAtEndOfSimTime);

    // clock callback
    // TODO: support multiple clocks with different frequencies

    vpiHandle event_obj = vpi_handle_by_name("remu_replay.internal.global_event", 0);
    if (event_obj == 0) {
        vpi_printf("ERROR: failed to get remu_replay.internal.global_event\n");
        vpi_control(vpiFinish);
        return;
    }

    static std::vector<vpiHandle> clock_objs;
    for (auto &info : loader->sysinfo.clock) {
        vpiHandle obj = vpiHandleByPath(info.name, 0);
        clock_objs.push_back(obj);
    }

    static bool clock_value = false;
    static VPICallback clock_cb([event_obj](uint64_t time) {
        clock_value = !clock_value;
        vpiSetValue(event_obj, clock_value, vpiForceFlag);
        // vpiForceFlag is used in case clock signal is initialized to Z after cbStartOfSimulation callback
        for (auto obj : clock_objs)
            vpiSetValue(obj, clock_value, vpiForceFlag);
        // Toggle clock every half of a period
        // cbAtStartOfSimTime is used in case loaded values are overwritten by scheduled NBAs
        clock_cb.register_callback(time + period / 2, cbAtStartOfSimTime);
        return 0;
    });
    // In iverilog cbAtStartOfSimTime callbacks cannot happen at time 0
    // So cbStartOfSimulation is used instead
    clock_cb.register_callback(0, cbStartOfSimulation);

    // signals

    static std::map<size_t, VPICallback> signal_cbs;
    const auto &signal_info = loader->sysinfo.signal;
    for (size_t index = 0; index < signal_info.size(); index++) {
        auto &info = signal_info[index];
        if (info.output)
            continue;

        vpiHandle obj = vpiHandleByPath(info.name, 0);

        auto &trace = loader->trace;
        if (trace.find(index) == trace.end())
            continue;

        auto &sig_data = trace.at(index);

        auto pos = sig_data.begin();
        auto end = sig_data.end();

        signal_cbs.insert(std::make_pair(index, [obj, init_tick, pos, end](uint64_t time) mutable {
            while (pos != end) {
                auto tick = time / period + init_tick;
                if (tick < pos->first)
                    break;

                // use vpiInertialDelay according to cocotb
                vpiSetValue(obj, pos->second, vpiInertialDelay);
                ++pos;
            }
            return 0;
        }));
        signal_cbs.at(index).register_callback(0, cbValueChange, event_obj);
    }

    // Stop simulator at end of trace

    static VPICallback eot_cb([](uint64_t) {
        vpi_control(vpiFinish);
        return 0;
    });
    eot_cb.register_callback((loader->latest_tick - init_tick) * period, cbAtEndOfSimTime);
}

void REMU::register_callback(VPILoader *loader)
{
    static VPICallback initial_cb([loader](uint64_t) {
        replay_initialize(loader);
        return 0;
    });
    initial_cb.register_callback(0, cbStartOfSimulation);
}
