`ifndef __AXI4_A_H__
`define __AXI4_A_H__

`include "axi.vh"

`define _AXI4_A_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4_DEF_FIELD(key1, prefix, avalid,      1), \
    `_AXI4_DEF_FIELD(key2, prefix, aready,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, awrite,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, aaddr,       addr_width), \
    `_AXI4_DEF_FIELD(key1, prefix, aid,         id_width), \
    `_AXI4_DEF_FIELD(key1, prefix, alen,        8), \
    `_AXI4_DEF_FIELD(key1, prefix, asize,       3), \
    `_AXI4_DEF_FIELD(key1, prefix, aburst,      2)

`define _AXI4_A_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4_DEF_FIELD(key, prefix, avalid,       1); \
    `_AXI4_DEF_FIELD(key, prefix, aready,       1); \
    `_AXI4_DEF_FIELD(key, prefix, awrite,       1); \
    `_AXI4_DEF_FIELD(key, prefix, aaddr,        addr_width); \
    `_AXI4_DEF_FIELD(key, prefix, aid,          id_width); \
    `_AXI4_DEF_FIELD(key, prefix, alen,         8); \
    `_AXI4_DEF_FIELD(key, prefix, asize,        3); \
    `_AXI4_DEF_FIELD(key, prefix, aburst,       2)

`define AXI4_A_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_A_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_A_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_A_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_A_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_A_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

`define AXI4_A_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_A_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

`define AXI4_A_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_A_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

`define AXI4_A_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, avalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, aready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awrite), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, aaddr), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, aid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, alen), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, asize), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, aburst)

`define AXI4_A_PAYLOAD(prefix) { \
    prefix``_awrite, \
    prefix``_aaddr, \
    prefix``_aid, \
    prefix``_alen, \
    prefix``_asize, \
    prefix``_aburst }

`define AXI4_A_PAYLOAD_FROM_AR(prefix) { \
    1'b0, \
    prefix``_araddr, \
    prefix``_arid, \
    prefix``_arlen, \
    prefix``_arsize, \
    prefix``_arburst }

`define AXI4_A_PAYLOAD_FROM_AW(prefix) { \
    1'b1, \
    prefix``_awaddr, \
    prefix``_awid, \
    prefix``_awlen, \
    prefix``_awsize, \
    prefix``_awburst }

`define AXI4_A_PAYLOAD_LEN(addr_width, data_width, id_width) ((addr_width) + (id_width) + 14)

`endif // `ifndef __AXI4_A_H__
