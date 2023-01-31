#include "replay_vpi.h"
#include "model.h"

#include <map>
#include <string>
#include <vector>

#include <vpi_user.h>

#include "escape.h"

using namespace REMU;

namespace {

std::vector<vpiHandle> tf_get_args(vpiHandle callh) {
    vpiHandle argv = vpi_iterate(vpiArgument, callh);
    std::vector<vpiHandle> args;
    while (vpiHandle arg = vpi_scan(argv))
        args.push_back(arg);
    return args;
}

bool get_value_as_bool(vpiHandle obj) {
    s_vpi_value value;
    value.format = vpiScalarVal;

    vpi_get_value(obj, &value);

    return value.value.scalar == vpi1;
}

template <typename T>
T get_value_as(vpiHandle obj) {
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

REMU::BitVector get_value_as_bitvector(vpiHandle obj) {
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

void set_value(vpiHandle obj, bool val) {
    s_vpi_value value;
    value.format = vpiScalarVal;
    value.value.scalar = val ? vpi1 : vpi0;

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

template <typename T>
void set_value(vpiHandle obj, T val) {
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

void set_value(vpiHandle obj, const REMU::BitVector &val) {
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

std::vector<std::string> get_full_path(vpiHandle obj)
{
    std::vector<std::string> res;
    do {
        res.push_back(vpi_get_str(vpiName, obj));
        obj = vpi_handle(vpiScope, obj);
    } while (obj != 0);
    return res;
}

void load_scope(const CircuitInfo &circuit, vpiHandle parent)
{
    for (auto &it : circuit.regs) {
        auto name = Escape::escape_verilog_id(it.first);
        vpiHandle obj = vpi_handle_by_name(name.c_str(), parent);
        if (obj == 0) {
            vpi_printf("WARNING: %s cannot be referenced (in scope %s)\n",
                name.c_str(), vpi_get_str(vpiFullName, parent));
            continue;
        }
        set_value(obj, it.second.data);
    }
    for (auto &it : circuit.regarrays) {
        auto name = Escape::escape_verilog_id(it.first);
        vpiHandle obj = vpi_handle_by_name(name.c_str(), parent);
        if (obj == 0) {
            vpi_printf("WARNING: %s cannot be referenced (in scope %s)\n",
                name.c_str(), vpi_get_str(vpiFullName, parent));
            continue;
        }
        auto &data = it.second.data;
        int depth = data.depth();
        int start_offset = it.second.start_offset;
        for (int i = 0; i < depth; i++) {
            int index = i + start_offset;
            vpiHandle word_obj = vpi_handle_by_index(obj, index);
            if (word_obj == 0) {
                vpi_printf("WARNING: %s[%d] cannot be referenced (in scope %s)\n",
                    name.c_str(), index, vpi_get_str(vpiFullName, parent));
                continue;
            }
            set_value(word_obj, data.get(i));
        }
    }
    for (auto it : circuit.cells) {
        auto name = Escape::escape_verilog_id(it.first);
        vpiHandle obj = vpi_handle_by_name(name.c_str(), parent);
        if (obj == 0) {
            vpi_printf("WARNING: %s cannot be referenced (in scope %s)\n",
                name.c_str(), vpi_get_str(vpiFullName, parent));
            continue;
        }
        load_scope(*it.second, obj);
    }
}

};

void VPILoader::load()
{
    load_scope(*circuit, 0);
}

namespace {

class Callback {

    virtual void execute() {}

    static PLI_INT32 __callback_routine(p_cb_data cb_data) {
        auto callback = reinterpret_cast<Callback*>(cb_data->user_data);
        callback->execute();
        return 0;
    }

public:

    void register_after_delay(uint64_t delay, bool start_time) {
        s_vpi_time cb_time;
        cb_time.type = vpiSimTime;
        vpi_get_time(0, &cb_time);

        uint64_t timeval = ((uint64_t)cb_time.high << 32) | cb_time.low;
        timeval += delay;
        cb_time.high = (uint32_t)(timeval >> 32);
        cb_time.low  = (uint32_t)timeval;

        s_cb_data cb_data;
        cb_data.reason = start_time ? cbAtStartOfSimTime : cbAtEndOfSimTime;
        cb_data.obj = 0;
        cb_data.time = &cb_time;
        cb_data.cb_rtn = __callback_routine;
        cb_data.user_data = reinterpret_cast<PLI_BYTE8 *>(this);
        vpi_register_cb(&cb_data);
    }

};

std::vector<RamModel> rammodel_list;

int rammodel_new_tf(char* user_data) {
    auto loader = reinterpret_cast<VPILoader*>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, -1);
        return 0;
    }

    uint32_t addr_width, data_width, id_width;
    uint64_t mem_size;
    addr_width  = get_value_as<uint32_t>(args[0]);
    data_width  = get_value_as<uint32_t>(args[1]);
    id_width    = get_value_as<uint32_t>(args[2]);
    mem_size    = get_value_as<uint64_t>(args[3]);

    size_t index = rammodel_list.size();
    rammodel_list.emplace_back(addr_width, data_width, id_width, mem_size);

    vpiHandle scope = vpi_handle(vpiScope, callh);
    std::string name = vpi_get_str(vpiFullName, scope);
    vpi_printf("rammodel info: %s registered with handle %ld\n", name.c_str(), index);

    auto data_stream = loader->checkpoint.readItem(name + ".host_axi");
    if (!rammodel_list[index].load_data(data_stream)) {
        vpi_printf("ERROR: failed to load rammodel data from checkpoint\n");
        set_value(callh, -1);
        return 0;
    }

    auto path = get_full_path(scope);
    rammodel_list[index].load_state(loader->circuit->cell(path));

    set_value(callh, index);
    return 0;
}

int rammodel_reset_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].reset();
    if (!res) {
        vpi_printf("%s: reset failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

int rammodel_a_req_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 7) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    RamModel::AChannel payload = {
        .addr    = get_value_as<uint64_t>(args[2]),
        .id      = get_value_as<uint16_t>(args[1]),
        .len     = get_value_as<uint8_t>(args[3]),
        .size    = get_value_as<uint8_t>(args[4]),
        .burst   = get_value_as<uint8_t>(args[5]),
        .write   = get_value_as_bool(args[6])
    };

    bool res = rammodel_list[index].a_req(payload);
    if (!res) {
        vpi_printf("%s: A req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

int rammodel_w_req_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    RamModel::WChannel payload = {
        .data   = get_value_as_bitvector(args[1]),
        .strb   = get_value_as_bitvector(args[2]),
        .last   = get_value_as_bool(args[3])
    };

    bool res = rammodel_list[index].w_req(payload);
    if (!res) {
        vpi_printf("%s: W req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

int rammodel_b_req_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 2) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    RamModel::BChannel payload = {
        .id = get_value_as<uint16_t>(args[1])
    };
    bool res = rammodel_list[index].b_req(payload);
    if (!res) {
        vpi_printf("%s: B req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

int rammodel_b_ack_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].b_ack();
    if (!res) {
        vpi_printf("%s: B ack failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

int rammodel_r_req_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    RamModel::RChannel payload = {
        .data   = BitVector(1),
        .id     = get_value_as<uint16_t>(args[1]),
        .last   = false
    };
    bool res = rammodel_list[index].r_req(payload);
    if (!res) {
        vpi_printf("%s: R req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(args[2], payload.data);
    set_value(args[3], payload.last);

    set_value(callh, 1);
    return 0;
}

int rammodel_r_ack_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    uint32_t index = get_value_as<uint32_t>(args[0]);
    if (index >= rammodel_list.size()) {
        vpi_printf("%s: invalid index\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    bool res = rammodel_list[index].r_ack();
    if (!res) {
        vpi_printf("%s: R ack failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

class CycleCallback : public Callback {
    vpiHandle m_obj;
    uint64_t m_cycle;
    virtual void execute() override {
        uint64_t val = get_value_as<uint64_t>(m_obj);
        set_value(m_obj, val + 1);
        register_after_delay(m_cycle, false);
    }

public:
    CycleCallback(vpiHandle obj, uint64_t cycle) : m_obj(obj), m_cycle(cycle) {}
};

int cycle_sig_tf(char* user_data) {
    auto loader = reinterpret_cast<VPILoader*>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 1) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        return 0;
    }

    set_value(args[0], loader->checkpoint.getTick());
    auto callback = new CycleCallback(args[0], 10000); // TODO: set cycle value
    callback->register_after_delay(10000, false);

    return 0;
}

int get_init_cycle_tf(char* user_data) {
    auto loader = reinterpret_cast<VPILoader*>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);

    set_value(callh, loader->checkpoint.getTick());
    return 0;
}

int get_init_cycle_sizetf(char* user_data) {
    static_cast<void>(user_data);
    return 64;
}

PLI_INT32 load_callback(p_cb_data cb_data) {
    auto loader = reinterpret_cast<VPILoader*>(cb_data->user_data);
    loader->load();
    return 0;
}

}; // namespace

void REMU::register_tfs(REMU::VPILoader *loader) {
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

    tf_data.type        = vpiSysTask;
    tf_data.tfname      = "$cycle_sig";
    tf_data.calltf      = cycle_sig_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiSizedFunc;
    tf_data.tfname      = "$get_init_cycle";
    tf_data.calltf      = get_init_cycle_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = get_init_cycle_sizetf;
    tf_data.user_data   = user_data;
    vpi_register_systf(&tf_data);
}

void REMU::register_load_callback(VPILoader *loader) {
    s_vpi_time cb_time;
    cb_time.type = vpiSimTime;
    vpi_get_time(0, &cb_time);

    s_cb_data cb_data;
    cb_data.reason = cbAtEndOfSimTime;
    cb_data.obj = 0;
    cb_data.time = &cb_time;
    cb_data.cb_rtn = load_callback;
    cb_data.user_data = reinterpret_cast<PLI_BYTE8 *>(loader);
    vpi_register_cb(&cb_data);
}
