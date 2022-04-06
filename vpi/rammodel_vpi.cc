#include "replay.h"
#include "rammodel.h"

#include <vector>
#include <map>

using namespace Replay;

static std::vector<RamModel> rammodel_list;
static std::map<std::string, std::string> rammodel_init_map;

static int rammodel_new_tf(char* user_data) {
    static_cast<void>(user_data);
    vpiHandle callh = vpi_handle(vpiSysTfCall, 0);
    auto args = tf_get_args(callh);

    if (args.size() != 4) {
        vpi_printf("%s: wrong number of arguments\n", __func__);
        set_value(callh, -1);
        return 0;
    }

    uint32_t addr_width, data_width, id_width, pf_count;
    addr_width  = get_value_as<uint32_t>(args[0]);
    data_width  = get_value_as<uint32_t>(args[1]);
    id_width    = get_value_as<uint32_t>(args[2]);
    pf_count    = get_value_as<uint32_t>(args[3]);

    uint32_t index = rammodel_list.size();
    rammodel_list.emplace_back(addr_width, data_width, id_width, pf_count);

    vpiHandle scope = vpi_handle(vpiScope, callh);
    std::string name = vpi_get_str(vpiFullName, scope);
    vpi_printf("rammodel info: %s registered with handle %d\n", name.c_str(), index);

    if (rammodel_init_map.find(name) != rammodel_init_map.end()) {
        std::string file = rammodel_init_map.at(name);
        vpi_printf("rammodel info: initializing %s with file %s\n", name.c_str(), file.c_str());

        std::ifstream stream(file, std::ios::binary);
        if (stream.fail()) {
            vpi_printf("ERROR: failed to open file %s\n", file.c_str());
            set_value(callh, -1);
            return 0;
        }

        rammodel_list[index].load_data(stream);
    }

    set_value(callh, index);
    return 0;
}

static int rammodel_reset_tf(char* user_data) {
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

static int rammodel_a_req_tf(char* user_data) {
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

    RamModel::AChannel payload;
    payload.id      = get_value_as<RamModel::id_t>(args[1]);
    payload.addr    = get_value_as<RamModel::addr_t>(args[2]);
    payload.len     = get_value_as<uint8_t>(args[3]);
    payload.size    = get_value_as<uint8_t>(args[4]);
    payload.burst   = get_value_as<uint8_t>(args[5]);
    payload.write   = get_value_as_bool(args[6]);

    bool res = rammodel_list[index].a_req(payload);
    if (!res) {
        vpi_printf("%s: A req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

static int rammodel_w_req_tf(char* user_data) {
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

    RamModel::WChannel payload;
    payload.data    = get_value_as<RamModel::data_t>(args[1]);
    payload.strb    = get_value_as<RamModel::strb_t>(args[2]);
    payload.last    = get_value_as_bool(args[3]);

    bool res = rammodel_list[index].w_req(payload);
    if (!res) {
        vpi_printf("%s: W req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

static int rammodel_b_req_tf(char* user_data) {
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

    RamModel::BChannel payload;
    payload.id = get_value_as<RamModel::id_t>(args[1]);
    bool res = rammodel_list[index].b_req(payload);
    if (!res) {
        vpi_printf("%s: B req failed\n", __func__);
        set_value(callh, 0);
        return 0;
    }

    set_value(callh, 1);
    return 0;
}

static int rammodel_b_ack_tf(char* user_data) {
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

static int rammodel_r_req_tf(char* user_data) {
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

    RamModel::RChannel payload;
    payload.id = get_value_as<RamModel::id_t>(args[1]);
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

static int rammodel_r_ack_tf(char* user_data) {
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

static void register_tfs() {
    s_vpi_systf_data tf_data;

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_new";
    tf_data.calltf      = rammodel_new_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
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
    tf_data.tfname      = "$rammodel_a_req";
    tf_data.calltf      = rammodel_a_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_w_req";
    tf_data.calltf      = rammodel_w_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_req";
    tf_data.calltf      = rammodel_b_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_b_ack";
    tf_data.calltf      = rammodel_b_ack_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_req";
    tf_data.calltf      = rammodel_r_req_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);

    tf_data.type        = vpiSysFunc;
    tf_data.sysfunctype = vpiIntFunc;
    tf_data.tfname      = "$rammodel_r_ack";
    tf_data.calltf      = rammodel_r_ack_tf;
    tf_data.compiletf   = 0;
    tf_data.sizetf      = 0;
    tf_data.user_data   = 0;
    vpi_register_systf(&tf_data);
}

void rammodel_main(std::vector<std::string> args) {
    register_tfs();

    for (size_t i = 0; i < args.size(); i++) {
        if (args[i] == "-rammodel-init" && i+2 < args.size()) {
            std::string name = args[++i];
            std::string file = args[++i];
            rammodel_init_map[name] = file;
        }
    }

}
