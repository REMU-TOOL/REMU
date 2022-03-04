`ifndef __AXI4_CUSTOM_H__
`define __AXI4_CUSTOM_H__

`define _AXI4_CUSTOM_DEF_FIELD(keyword, prefix, name, width) \
    keyword [(width)-1:0] prefix``_``name

`define _AXI4_CUSTOM_CON_FIELD(if_prefix, wire_prefix, name) \
    .if_prefix``_``name(wire_prefix``_``name)

`define _AXI4_CUSTOM_A_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, avalid,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key2, prefix, aready,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, awrite,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, aaddr,       addr_width), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, aid,         id_width), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, alen,        8), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, asize,       3), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, aburst,      2)

`define _AXI4_CUSTOM_A_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, avalid,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, aready,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, awrite,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, aaddr,        addr_width); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, aid,          id_width); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, alen,         8); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, asize,        3); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, aburst,       2)

`define AXI4_CUSTOM_A_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_A_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_A_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_A_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_A_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_A_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_A_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_A_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_A_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_A_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_A_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, avalid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, aready), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, awrite), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, aaddr), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, aid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, alen), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, asize), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, aburst)

`define AXI4_CUSTOM_A_PAYLOAD(prefix) { \
    prefix``_awrite, \
    prefix``_aaddr, \
    prefix``_aid, \
    prefix``_alen, \
    prefix``_asize, \
    prefix``_aburst }

`define AXI4_CUSTOM_A_PAYLOAD_FROM_AR(prefix) { \
    1'b0, \
    prefix``_araddr, \
    prefix``_arid, \
    prefix``_arlen, \
    prefix``_arsize, \
    prefix``_arburst }

`define AXI4_CUSTOM_A_PAYLOAD_FROM_AW(prefix) { \
    1'b1, \
    prefix``_awaddr, \
    prefix``_awid, \
    prefix``_awlen, \
    prefix``_awsize, \
    prefix``_awburst }

`define AXI4_CUSTOM_A_PAYLOAD_LEN(addr_width, data_width, id_width) ((addr_width) + (id_width) + 14)

`define _AXI4_CUSTOM_W_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, wvalid,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key2, prefix, wready,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, wdata,       data_width), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, wstrb,       (data_width/8)), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, wlast,       1)

`define _AXI4_CUSTOM_W_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, wvalid,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, wready,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, wdata,        data_width); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, wstrb,        (data_width/8)); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, wlast,        1)

`define AXI4_CUSTOM_W_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_W_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_W_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_W_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_W_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_W_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_W_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_W_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_W_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_W_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_W_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, wvalid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, wready), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, wdata), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, wstrb), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, wlast)

`define AXI4_CUSTOM_W_PAYLOAD(prefix) { \
    prefix``_wdata, \
    prefix``_wstrb, \
    prefix``_wlast }

`define AXI4_CUSTOM_W_PAYLOAD_LEN(addr_width, data_width, id_width)    (data_width + data_width/8 + 1)

`define AXI4_CUSTOM_W_PAYLOAD_WO_LAST(prefix) { \
    prefix``_wdata, \
    prefix``_wstrb }

`define AXI4_CUSTOM_W_PAYLOAD_WO_LAST_LEN(addr_width, data_width, id_width)    (data_width + data_width/8)

`define _AXI4_CUSTOM_B_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, bvalid,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key2, prefix, bready,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, bid,         id_width)

`define _AXI4_CUSTOM_B_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, bvalid,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, bready,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, bid,          id_width)

`define AXI4_CUSTOM_B_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_B_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_B_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_B_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_B_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_B_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_B_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_B_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_B_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_B_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_B_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, bvalid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, bready), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, bid)

`define AXI4_CUSTOM_B_PAYLOAD(prefix) { \
    prefix``_bid }

`define AXI4_CUSTOM_B_PAYLOAD_LEN(addr_width, data_width, id_width)    (id_width)

`define _AXI4_CUSTOM_R_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, rvalid,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key2, prefix, rready,      1), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, rdata,       data_width), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, rid,         id_width), \
    `_AXI4_CUSTOM_DEF_FIELD (key1, prefix, rlast,       1)

`define _AXI4_CUSTOM_R_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, rvalid,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, rready,       1); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, rdata,        data_width); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, rid,          id_width); \
    `_AXI4_CUSTOM_DEF_FIELD (key, prefix, rlast,        1)

`define AXI4_CUSTOM_R_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_R_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_R_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_R_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_R_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_R_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_R_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_R_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_R_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_CUSTOM_R_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

`define AXI4_CUSTOM_R_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, rvalid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, rready), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, rdata), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, rid), \
    `_AXI4_CUSTOM_CON_FIELD (if_prefix, wire_prefix, rlast)

`define AXI4_CUSTOM_R_PAYLOAD(prefix) { \
    prefix``_rdata, \
    prefix``_rid, \
    prefix``_rlast }

`define AXI4_CUSTOM_R_PAYLOAD_LEN(addr_width, data_width, id_width)    (data_width + id_width + 1)

`define AXI4_CUSTOM_R_PAYLOAD_WO_LAST(prefix) { \
    prefix``_rdata, \
    prefix``_rid }

`define AXI4_CUSTOM_R_PAYLOAD_WO_LAST_LEN(addr_width, data_width, id_width)    (data_width + id_width)

`endif // `ifndef __AXI4_CUSTOM_H__
