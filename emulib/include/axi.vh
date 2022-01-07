`define _AXI4_DEF_FIELD(keyword, prefix, name, width) \
    keyword [width-1:0] prefix``_``name

`define _AXI4_CON_FIELD(if_prefix, wire_prefix, name) \
    .if_prefix``_``name(wire_prefix``_``name)

`define _AXI4LITE_PORT_DECL(key1, key2, prefix, addr_width, data_width) \
    `_AXI4_DEF_FIELD(key1, prefix, awvalid,     1), \
    `_AXI4_DEF_FIELD(key2, prefix, awready,     1), \
    `_AXI4_DEF_FIELD(key1, prefix, awaddr,      addr_width), \
    `_AXI4_DEF_FIELD(key1, prefix, awprot,      3), \
    `_AXI4_DEF_FIELD(key1, prefix, wvalid,      1), \
    `_AXI4_DEF_FIELD(key2, prefix, wready,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, wdata,       data_width), \
    `_AXI4_DEF_FIELD(key1, prefix, wstrb,       (data_width/8)), \
    `_AXI4_DEF_FIELD(key2, prefix, bvalid,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, bready,      1), \
    `_AXI4_DEF_FIELD(key2, prefix, bresp,       2), \
    `_AXI4_DEF_FIELD(key1, prefix, arvalid,     1), \
    `_AXI4_DEF_FIELD(key2, prefix, arready,     1), \
    `_AXI4_DEF_FIELD(key1, prefix, araddr,      addr_width), \
    `_AXI4_DEF_FIELD(key1, prefix, arprot,      3), \
    `_AXI4_DEF_FIELD(key2, prefix, rvalid,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, rready,      1), \
    `_AXI4_DEF_FIELD(key2, prefix, rdata,       data_width), \
    `_AXI4_DEF_FIELD(key2, prefix, rresp,       2)

`define _AXI4LITE_ITEM_DECL(key, prefix, addr_width, data_width) \
    `_AXI4_DEF_FIELD(key, prefix, awvalid,      1); \
    `_AXI4_DEF_FIELD(key, prefix, awready,      1); \
    `_AXI4_DEF_FIELD(key, prefix, awaddr,       addr_width); \
    `_AXI4_DEF_FIELD(key, prefix, awprot,       3); \
    `_AXI4_DEF_FIELD(key, prefix, wvalid,       1); \
    `_AXI4_DEF_FIELD(key, prefix, wready,       1); \
    `_AXI4_DEF_FIELD(key, prefix, wdata,        data_width); \
    `_AXI4_DEF_FIELD(key, prefix, wstrb,        (data_width/8)); \
    `_AXI4_DEF_FIELD(key, prefix, bvalid,       1); \
    `_AXI4_DEF_FIELD(key, prefix, bready,       1); \
    `_AXI4_DEF_FIELD(key, prefix, bresp,        2); \
    `_AXI4_DEF_FIELD(key, prefix, arvalid,      1); \
    `_AXI4_DEF_FIELD(key, prefix, arready,      1); \
    `_AXI4_DEF_FIELD(key, prefix, araddr,       addr_width); \
    `_AXI4_DEF_FIELD(key, prefix, arprot,       3); \
    `_AXI4_DEF_FIELD(key, prefix, rvalid,       1); \
    `_AXI4_DEF_FIELD(key, prefix, rready,       1); \
    `_AXI4_DEF_FIELD(key, prefix, rdata,        data_width); \
    `_AXI4_DEF_FIELD(key, prefix, rresp,        2)

// Define an AXI4-Lite slave interface in module port declaration
`define AXI4LITE_SLAVE_IF(prefix, addr_width, data_width) \
    `_AXI4LITE_PORT_DECL(input wire, output wire, prefix, addr_width, data_width)

// Define an AXI4-Lite master interface in module port declaration
`define AXI4LITE_MASTER_IF(prefix, addr_width, data_width) \
    `_AXI4LITE_PORT_DECL(output wire, input wire, prefix, addr_width, data_width)

// Define an AXI4-Lite monitor input interface in module port declaration
`define AXI4LITE_INPUT_IF(prefix, addr_width, data_width) \
    `_AXI4LITE_PORT_DECL(input wire, input wire, prefix, addr_width, data_width)

// Define an AXI4-Lite monitor input interface in module port declaration
`define AXI4LITE_OUTPUT_IF(prefix, addr_width, data_width) \
    `_AXI4LITE_PORT_DECL(output wire, output wire, prefix, addr_width, data_width)

// Define an AXI4-Lite wire bundle in module context
`define AXI4LITE_WIRE(prefix, addr_width, data_width) \
    `_AXI4LITE_ITEM_DECL(wire, prefix, addr_width, data_width)

// Connect an AXI4-Lite interface with another in module instantiation
`define AXI4LITE_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awaddr), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awprot), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wdata), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wstrb), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bresp), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, araddr), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arprot), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rdata), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rresp)

// List of AXI4-Lite AW channel payload fields
`define AXI4LITE_AW_PAYLOAD(prefix) { \
    prefix``_awaddr, \
    prefix``_awprot }

// List of AXI4-Lite W channel payload fields
`define AXI4LITE_W_PAYLOAD(prefix) { \
    prefix``_wdata, \
    prefix``_wstrb }

// List of AXI4-Lite B channel payload fields
`define AXI4LITE_B_PAYLOAD(prefix) { \
    prefix``_bresp }

// List of AXI4-Lite AR channel payload fields
`define AXI4LITE_AR_PAYLOAD(prefix) { \
    prefix``_araddr, \
    prefix``_arprot }

// List of AXI4-Lite R channel payload fields
`define AXI4LITE_R_PAYLOAD(prefix) { \
    prefix``_rdata, \
    prefix``_rresp }

// Length of AXI4-Lite AW channel payload fields
`define AXI4LITE_AW_PAYLOAD_LEN(addr_width, data_width, id_width)   (addr_width + 3)

// Length of AXI4-Lite W channel payload fields
`define AXI4LITE_W_PAYLOAD_LEN(addr_width, data_width, id_width)    (data_width + data_width/8)

// Length of AXI4-Lite B channel payload fields
`define AXI4LITE_B_PAYLOAD_LEN(addr_width, data_width, id_width)    2

// Length of AXI4-Lite AR channel payload fields
`define AXI4LITE_AR_PAYLOAD_LEN(addr_width, data_width, id_width)   (addr_width + 3)

// Length of AXI4-Lite R channel payload fields
`define AXI4LITE_R_PAYLOAD_LEN(addr_width, data_width, id_width)    (data_width + 2)

`define _AXI4_PORT_DECL(key1, key2, prefix, addr_width, data_width, id_width) \
    `_AXI4LITE_PORT_DECL(key1, key2, prefix, addr_width, data_width), \
    `_AXI4_DEF_FIELD(key1, prefix, awid,        id_width), \
    `_AXI4_DEF_FIELD(key1, prefix, awlen,       8), \
    `_AXI4_DEF_FIELD(key1, prefix, awsize,      3), \
    `_AXI4_DEF_FIELD(key1, prefix, awburst,     2), \
    `_AXI4_DEF_FIELD(key1, prefix, awlock,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, awcache,     4), \
    `_AXI4_DEF_FIELD(key1, prefix, awqos,       4), \
    `_AXI4_DEF_FIELD(key1, prefix, awregion,    4), \
    `_AXI4_DEF_FIELD(key1, prefix, wlast,       1), \
    `_AXI4_DEF_FIELD(key2, prefix, bid,         id_width), \
    `_AXI4_DEF_FIELD(key1, prefix, arid,        id_width), \
    `_AXI4_DEF_FIELD(key1, prefix, arlen,       8), \
    `_AXI4_DEF_FIELD(key1, prefix, arsize,      3), \
    `_AXI4_DEF_FIELD(key1, prefix, arburst,     2), \
    `_AXI4_DEF_FIELD(key1, prefix, arlock,      1), \
    `_AXI4_DEF_FIELD(key1, prefix, arcache,     4), \
    `_AXI4_DEF_FIELD(key1, prefix, arqos,       4), \
    `_AXI4_DEF_FIELD(key1, prefix, arregion,    4), \
    `_AXI4_DEF_FIELD(key2, prefix, rid,         id_width), \
    `_AXI4_DEF_FIELD(key2, prefix, rlast,       1)

`define _AXI4_ITEM_DECL(key, prefix, addr_width, data_width, id_width) \
    `_AXI4LITE_ITEM_DECL(key, prefix, addr_width, data_width); \
    `_AXI4_DEF_FIELD(key, prefix, awid,        id_width); \
    `_AXI4_DEF_FIELD(key, prefix, awlen,       8); \
    `_AXI4_DEF_FIELD(key, prefix, awsize,      3); \
    `_AXI4_DEF_FIELD(key, prefix, awburst,     2); \
    `_AXI4_DEF_FIELD(key, prefix, awlock,      1); \
    `_AXI4_DEF_FIELD(key, prefix, awcache,     4); \
    `_AXI4_DEF_FIELD(key, prefix, awqos,       4); \
    `_AXI4_DEF_FIELD(key, prefix, awregion,    4); \
    `_AXI4_DEF_FIELD(key, prefix, wlast,       1); \
    `_AXI4_DEF_FIELD(key, prefix, bid,         id_width); \
    `_AXI4_DEF_FIELD(key, prefix, arid,        id_width); \
    `_AXI4_DEF_FIELD(key, prefix, arlen,       8); \
    `_AXI4_DEF_FIELD(key, prefix, arsize,      3); \
    `_AXI4_DEF_FIELD(key, prefix, arburst,     2); \
    `_AXI4_DEF_FIELD(key, prefix, arlock,      1); \
    `_AXI4_DEF_FIELD(key, prefix, arcache,     4); \
    `_AXI4_DEF_FIELD(key, prefix, arqos,       4); \
    `_AXI4_DEF_FIELD(key, prefix, arregion,    4); \
    `_AXI4_DEF_FIELD(key, prefix, rid,         id_width); \
    `_AXI4_DEF_FIELD(key, prefix, rlast,       1)

// Define an AXI4 slave interface in module port declaration
`define AXI4_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_PORT_DECL(input wire, output wire, prefix, addr_width, data_width, id_width)

// Define an AXI4 master interface in module port declaration
`define AXI4_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_PORT_DECL(output wire, input wire, prefix, addr_width, data_width, id_width)

// Define an AXI4 monitor input interface in module port declaration
`define AXI4_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_PORT_DECL(input wire, input wire, prefix, addr_width, data_width, id_width)

// Define an AXI4 monitor output interface in module port declaration
`define AXI4_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4_PORT_DECL(output wire, output wire, prefix, addr_width, data_width, id_width)

// Define an AXI4 wire bundle in module context
`define AXI4_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4_ITEM_DECL(wire, prefix, addr_width, data_width, id_width)

// Connect an AXI4 interface with another in module instantiation
`define AXI4_CONNECT(if_prefix, wire_prefix) \
    `AXI4LITE_CONNECT(if_prefix, wire_prefix), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awlen), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awsize), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awburst), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awlock), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awcache), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awqos), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awregion), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wlast), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arlen), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arsize), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arburst), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arlock), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arcache), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arqos), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arregion), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rlast)

// List of AXI4 AW channel payload fields
`define AXI4_AW_PAYLOAD(prefix) { \
    `AXI4LITE_AW_PAYLOAD(prefix), \
    prefix``_awid, \
    prefix``_awlen, \
    prefix``_awsize, \
    prefix``_awburst, \
    prefix``_awlock, \
    prefix``_awcache, \
    prefix``_awqos, \
    prefix``_awregion }

// List of AXI4 W channel payload fields
`define AXI4_W_PAYLOAD(prefix) { \
    `AXI4LITE_W_PAYLOAD(prefix), \
    prefix``_wlast }

// List of AXI4 B channel payload fields
`define AXI4_B_PAYLOAD(prefix) { \
    `AXI4LITE_B_PAYLOAD(prefix), \
    prefix``_bid }

// List of AXI4 AR channel payload fields
`define AXI4_AR_PAYLOAD(prefix) { \
    `AXI4LITE_AR_PAYLOAD(prefix), \
    prefix``_arid, \
    prefix``_arlen, \
    prefix``_arsize, \
    prefix``_arburst, \
    prefix``_arlock, \
    prefix``_arcache, \
    prefix``_arqos, \
    prefix``_arregion }

// List of AXI4 R channel payload fields
`define AXI4_R_PAYLOAD(prefix) { \
    `AXI4LITE_R_PAYLOAD(prefix), \
    prefix``_rid, \
    prefix``_rlast }

// Length of AXI4 AW channel payload fields
`define AXI4_AW_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_AW_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width + 26)

// Length of AXI4 W channel payload fields
`define AXI4_W_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_W_PAYLOAD_LEN(addr_width, data_width, id_width) + 1)

// Length of AXI4 B channel payload fields
`define AXI4_B_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_B_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width)

// Length of AXI4 AR channel payload fields
`define AXI4_AR_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_AR_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width + 26)

// Length of AXI4 R channel payload fields
`define AXI4_R_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_R_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width + 1)
