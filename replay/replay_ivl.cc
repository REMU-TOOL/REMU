#include "replay_ivl.h"
#include "model.h"
#include "vpi_utils.h"
#include "escape.h"
#include "emu_utils.h"

#include <map>
#include <string>
#include <vector>
#include <list>

using namespace REMU;

inline std::string get_full_name(const std::vector<std::string> &path)
{
    std::string full_name;
    bool first = true;
    for (auto &name : path) {
        std::string esc_name = Escape::escape_verilog_id(name);
        if (first)
            first = false;
        else
            full_name += ".";
        full_name += esc_name;
    }
    return full_name;
}

void VPILoader::load()
{
    circuit.load(ckpt);

    for (auto &it : circuit.wire) {
        std::string full_name = get_full_name(it.first);
        vpiHandle obj = vpi_handle_by_name(full_name.c_str(), 0);
        if (obj == 0) {
            if (!suppress_warning)
                vpi_printf("WARNING: %s cannot be referenced\n",
                    full_name.c_str());
            continue;
        }
        vpiSetValue(obj, it.second.data);
    }

    for (auto &it : circuit.ram) {
        if (it.second.dissolved)
            continue;
        std::string full_name = get_full_name(it.first);
        vpiHandle obj = vpi_handle_by_name(full_name.c_str(), 0);
        if (obj == 0) {
            if (!suppress_warning)
                vpi_printf("WARNING: %s cannot be referenced\n",
                    full_name.c_str());
            continue;
        }
        int depth = it.second.data.depth();
        int start_offset = it.second.data.start_offset();
        for (int i = 0; i < depth; i++) {
            int index = i + start_offset;
            vpiHandle word_obj = vpi_handle_by_index(obj, index);
            if (word_obj == 0) {
                if (!suppress_warning)
                    vpi_printf("WARNING: %s[%d] cannot be referenced\n",
                        vpi_get_str(vpiFullName, obj), index);
                continue;
            }
            vpiSetValue(word_obj, it.second.data.get(i));
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

    auto data_stream = loader->ckpt.axi_mems.at(name + ".host_axi").read();
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

int rammodel_reset_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    bool res = rammodel.reset();
    if (!res) {
        vpi_printf("%s: reset failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_ar_aw_push_tf(char* user_data)
{
    auto arg = reinterpret_cast<size_t>(user_data);
    bool is_aw = arg != 0;

    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = vpiGetTfArgs(callh);

    if (args.size() != 6) {
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
    auto &rammodel = rammodel_list[index];

    RamModel::AChannel payload = {
        .addr    = vpiGetValue<uint64_t>(args[2]),
        .id      = vpiGetValue<uint16_t>(args[1]),
        .len     = vpiGetValue<uint8_t>(args[3]),
        .size    = vpiGetValue<uint8_t>(args[4]),
        .burst   = vpiGetValue<uint8_t>(args[5]),
        .write   = is_aw
    };

    bool res = rammodel.a_push(payload);
    if (!res) {
        vpi_printf("%s: A req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_w_push_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    RamModel::WChannel payload = {
        .data   = vpiGetValue<BitVector>(args[1]),
        .strb   = vpiGetValue<BitVector>(args[2]),
        .last   = vpiGetValue<bool>(args[3])
    };

    bool res = rammodel.w_push(payload);
    if (!res) {
        vpi_printf("%s: W req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_b_front_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    RamModel::BChannel payload;
    bool res = rammodel.b_front(vpiGetValue<uint16_t>(args[1]), payload);
    if (!res) {
        vpi_printf("%s: B req failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_b_pop_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    bool res = rammodel.b_pop(vpiGetValue<uint16_t>(args[1]));
    if (!res) {
        vpi_printf("%s: B ack failed\n", __func__);
        vpiSetValue(callh, 0);
        return 0;
    }

    vpiSetValue(callh, 1);
    return 0;
}

int rammodel_r_front_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    RamModel::RChannel payload;
    bool res = rammodel.r_front(vpiGetValue<uint16_t>(args[1]), payload);
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

int rammodel_r_pop_tf(char*)
{
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
    auto &rammodel = rammodel_list[index];

    bool res = rammodel.r_pop(vpiGetValue<uint16_t>(args[1]));
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
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_ar_push";
    tf_data.calltf      = rammodel_ar_aw_push_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = reinterpret_cast<char*>(0);
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_aw_push";
    tf_data.calltf      = rammodel_ar_aw_push_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = reinterpret_cast<char*>(1);
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_w_push";
    tf_data.calltf      = rammodel_w_push_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_front";
    tf_data.calltf      = rammodel_b_front_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_pop";
    tf_data.calltf      = rammodel_b_pop_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_front";
    tf_data.calltf      = rammodel_r_front_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_pop";
    tf_data.calltf      = rammodel_r_pop_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);
}

static constexpr uint64_t period = 10000;

void replay_initialize(VPILoader *loader)
{
    // loader callback

    static VPICallback loader_cb([loader](uint64_t) {
        vpi_printf("INFO: loading checkpoint\n");
        loader->load();
        vpi_printf("INFO: checkpoint loaded, continuing simulation\n");
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
        vpiHandle obj = vpi_handle_by_name(flatten_name(info.name).c_str(), 0);
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

    static std::list<VPICallback> signal_cbs;
    const auto &signal_info = loader->sysinfo.signal;
    for (auto &info : signal_info) {
        if (info.output)
            continue;

        std::string name = flatten_name(info.name);
        vpiHandle obj = vpi_handle_by_name(name.c_str(), 0);

        auto &trace = loader->ckpt_mgr.signal_trace;
        if (trace.find(name) == trace.end())
            continue;

        auto &sig_data = trace.at(name);

        auto pos = sig_data.begin();
        auto end = sig_data.end();

        signal_cbs.push_back(VPICallback([obj, init_tick, pos, end](uint64_t time) mutable {
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
        signal_cbs.back().register_callback(0, cbValueChange, event_obj);
    }

    // Stop simulator at end of trace

    uint64_t last_tick = loader->ckpt_mgr.last_tick();
    static VPICallback eot_cb([last_tick](uint64_t) {
        vpi_printf("WARNING: No more signal traces after tick %lu. "
        "Replay will continue but input signals will remain unchanged\n", last_tick);
        return 0;
    });
    eot_cb.register_callback((last_tick - init_tick) * period, cbAtEndOfSimTime);
}

void REMU::register_callback(VPILoader *loader)
{
    static VPICallback initial_cb([loader](uint64_t) {
        replay_initialize(loader);
        return 0;
    });
    initial_cb.register_callback(0, cbStartOfSimulation);
}
