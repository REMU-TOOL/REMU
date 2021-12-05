`define _AXI_VH_DELIMITER_COMMA     ,
`define _AXI_VH_DELIMITER_SEMICOLON ;

`define _AXI4_DEF_FIELD(keyword, prefix, name, width) \
    keyword [width-1:0] prefix``_``name

`define _AXI4_CON_FIELD(if_prefix, wire_prefix, name) \
    .if_prefix``_``name(wire_prefix``_``name)

`define _AXI4LITE_DEF_AW(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4_DEF_FIELD(key1, prefix, awvalid,     1)              delimiter \
    `_AXI4_DEF_FIELD(key2, prefix, awready,     1)              delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, awaddr,      addr_width)     delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, awprot,      3)

`define _AXI4LITE_DEF_W(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4_DEF_FIELD(key1, prefix, wvalid,      1)              delimiter \
    `_AXI4_DEF_FIELD(key2, prefix, wready,      1)              delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, wdata,       data_width)     delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, wstrb,       (data_width/8))

`define _AXI4LITE_DEF_B(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4_DEF_FIELD(key1, prefix, bvalid,      1)              delimiter \
    `_AXI4_DEF_FIELD(key2, prefix, bready,      1)              delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, bresp,       2)

`define _AXI4LITE_DEF_AR(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4_DEF_FIELD(key1, prefix, arvalid,     1)              delimiter \
    `_AXI4_DEF_FIELD(key2, prefix, arready,     1)              delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, araddr,      addr_width)     delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, arprot,      3)

`define _AXI4LITE_DEF_R(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4_DEF_FIELD(key1, prefix, rvalid,      1)              delimiter \
    `_AXI4_DEF_FIELD(key2, prefix, rready,      1)              delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, rdata,       data_width)     delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, rresp,       2)

`define _AXI4LITE(key1, key2, prefix, addr_width, data_width, delimiter) \
    `_AXI4LITE_DEF_AW   (key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4LITE_DEF_W    (key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4LITE_DEF_B    (key2, key1, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4LITE_DEF_AR   (key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4LITE_DEF_R    (key2, key1, prefix, addr_width, data_width, delimiter)

// Define an AXI4-Lite slave interface in module port declaration
`define AXI4LITE_SLAVE_IF(prefix, addr_width, data_width) \
    `_AXI4LITE(input, output, prefix, addr_width, data_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4-Lite master interface in module port declaration
`define AXI4LITE_MASTER_IF(prefix, addr_width, data_width) \
    `_AXI4LITE(output, input, prefix, addr_width, data_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4-Lite monitor input interface in module port declaration
`define AXI4LITE_INPUT_IF(prefix, addr_width, data_width) \
    `_AXI4LITE(input, input, prefix, addr_width, data_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4-Lite monitor input interface in module port declaration
`define AXI4LITE_OUTPUT_IF(prefix, addr_width, data_width) \
    `_AXI4LITE(output, output, prefix, addr_width, data_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4-Lite wire bundle in module context
`define AXI4LITE_WIRE(prefix, addr_width, data_width) \
    `_AXI4LITE(wire, wire, prefix, addr_width, data_width, `_AXI_VH_DELIMITER_SEMICOLON)

`define _AXI4LITE_CON_AW(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awaddr), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, awprot)

`define _AXI4LITE_CON_W(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wdata), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wstrb)

`define _AXI4LITE_CON_B(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bresp)

`define _AXI4LITE_CON_AR(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, araddr), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, arprot)

`define _AXI4LITE_CON_R(if_prefix, wire_prefix) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rvalid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rready), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rdata), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rresp)

// Connect an AXI4-Lite interface with another in module instantiation
`define AXI4LITE_CONNECT(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_AW(if_prefix, wire_prefix), \
    `_AXI4LITE_CON_W(if_prefix, wire_prefix), \
    `_AXI4LITE_CON_B(if_prefix, wire_prefix), \
    `_AXI4LITE_CON_AR(if_prefix, wire_prefix), \
    `_AXI4LITE_CON_R(if_prefix, wire_prefix)

`define _AXI4LITE_AW_PAYLOAD(prefix) \
    prefix``_awaddr, \
    prefix``_awprot

`define _AXI4LITE_W_PAYLOAD(prefix) \
    prefix``_wdata, \
    prefix``_wstrb

`define _AXI4LITE_B_PAYLOAD(prefix) \
    prefix``_bresp

`define _AXI4LITE_AR_PAYLOAD(prefix) \
    prefix``_araddr, \
    prefix``_arprot

`define _AXI4LITE_R_PAYLOAD(prefix) \
    prefix``_rdata, \
    prefix``_rresp

// List of AXI4-Lite AW channel payload fields
`define AXI4LITE_AW_PAYLOAD(prefix) {`_AXI4LITE_AW_PAYLOAD(prefix)}

// List of AXI4-Lite W channel payload fields
`define AXI4LITE_W_PAYLOAD(prefix)  {`_AXI4LITE_W_PAYLOAD(prefix)}

// List of AXI4-Lite B channel payload fields
`define AXI4LITE_B_PAYLOAD(prefix)  {`_AXI4LITE_B_PAYLOAD(prefix)}

// List of AXI4-Lite AR channel payload fields
`define AXI4LITE_AR_PAYLOAD(prefix) {`_AXI4LITE_AR_PAYLOAD(prefix)}

// List of AXI4-Lite R channel payload fields
`define AXI4LITE_R_PAYLOAD(prefix)  {`_AXI4LITE_R_PAYLOAD(prefix)}

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

`define _AXI4_DEF_A_EXTRA_SIGS(key, prefix, a, id_width, delimiter) \
    `_AXI4_DEF_FIELD(key, prefix, a``id,        id_width)       delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``len,       8)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``size,      3)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``burst,     2)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``lock,      1)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``cache,     4)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``qos,       4)              delimiter \
    `_AXI4_DEF_FIELD(key, prefix, a``region,    4)

`define _AXI4_DEF_AW(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4LITE_DEF_AW(key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4_DEF_A_EXTRA_SIGS(key1, prefix, aw, id_width, delimiter)

`define _AXI4_DEF_W(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4LITE_DEF_W(key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, wlast,       1)

`define _AXI4_DEF_B(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4LITE_DEF_B(key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, bid,         id_width)

`define _AXI4_DEF_AR(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4LITE_DEF_AR(key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4_DEF_A_EXTRA_SIGS(key1, prefix, ar, id_width, delimiter)

`define _AXI4_DEF_R(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4LITE_DEF_R(key1, key2, prefix, addr_width, data_width, delimiter) delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, rid,         id_width)       delimiter \
    `_AXI4_DEF_FIELD(key1, prefix, rlast,       1)

`define _AXI4(key1, key2, prefix, addr_width, data_width, id_width, delimiter) \
    `_AXI4_DEF_AW   (key1, key2, prefix, addr_width, data_width, id_width, delimiter) delimiter \
    `_AXI4_DEF_W    (key1, key2, prefix, addr_width, data_width, id_width, delimiter) delimiter \
    `_AXI4_DEF_B    (key2, key1, prefix, addr_width, data_width, id_width, delimiter) delimiter \
    `_AXI4_DEF_AR   (key1, key2, prefix, addr_width, data_width, id_width, delimiter) delimiter \
    `_AXI4_DEF_R    (key2, key1, prefix, addr_width, data_width, id_width, delimiter)

// Define an AXI4 slave interface in module port declaration
`define AXI4_SLAVE_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4(input, output, prefix, addr_width, data_width, id_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4 master interface in module port declaration
`define AXI4_MASTER_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4(output, input, prefix, addr_width, data_width, id_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4 monitor input interface in module port declaration
`define AXI4_INPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4(input, input, prefix, addr_width, data_width, id_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4 monitor output interface in module port declaration
`define AXI4_OUTPUT_IF(prefix, addr_width, data_width, id_width) \
    `_AXI4(output, output, prefix, addr_width, data_width, id_width, `_AXI_VH_DELIMITER_COMMA)

// Define an AXI4 wire bundle in module context
`define AXI4_WIRE(prefix, addr_width, data_width, id_width) \
    `_AXI4(wire, wire, prefix, addr_width, data_width, id_width, `_AXI_VH_DELIMITER_SEMICOLON)

`define _AXI4_CON_A_EXTRA_SIGS(if_prefix, wire_prefix, a) \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``id), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``len), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``size), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``burst), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``lock), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``cache), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``qos), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, a``region)

`define _AXI4_CON_AW(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_AW(if_prefix, wire_prefix), \
    `_AXI4_CON_A_EXTRA_SIGS(if_prefix, wire_prefix, aw)

`define _AXI4_CON_W(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_W(if_prefix, wire_prefix), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, wlast)

`define _AXI4_CON_B(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_B(if_prefix, wire_prefix), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, bid)

`define _AXI4_CON_AR(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_AR(if_prefix, wire_prefix), \
    `_AXI4_CON_A_EXTRA_SIGS(if_prefix, wire_prefix, ar)

`define _AXI4_CON_R(if_prefix, wire_prefix) \
    `_AXI4LITE_CON_R(if_prefix, wire_prefix), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rid), \
    `_AXI4_CON_FIELD(if_prefix, wire_prefix, rlast)

// Connect an AXI4 interface with another in module instantiation
`define AXI4_CONNECT(if_prefix, wire_prefix) \
    `_AXI4_CON_AW(if_prefix, wire_prefix), \
    `_AXI4_CON_W(if_prefix, wire_prefix), \
    `_AXI4_CON_B(if_prefix, wire_prefix), \
    `_AXI4_CON_AR(if_prefix, wire_prefix), \
    `_AXI4_CON_R(if_prefix, wire_prefix)

`define _AXI4_A_EXTRA_SIGS_PAYLOAD(prefix, a) \
    prefix``_``a``id, \
    prefix``_``a``len, \
    prefix``_``a``size, \
    prefix``_``a``burst, \
    prefix``_``a``lock, \
    prefix``_``a``cache, \
    prefix``_``a``qos, \
    prefix``_``a``region

`define _AXI4_A_EXTRA_SIGS_PAYLOAD_LEN(id_width) (id_width + 26)

`define _AXI4_AW_PAYLOAD(prefix) \
    `_AXI4LITE_AW_PAYLOAD(prefix), \
    `_AXI4_A_EXTRA_SIGS_PAYLOAD(prefix, aw)

`define _AXI4_W_PAYLOAD(prefix) \
    `_AXI4LITE_W_PAYLOAD(prefix), \
    prefix``_wlast

`define _AXI4_B_PAYLOAD(prefix) \
    `_AXI4LITE_B_PAYLOAD(prefix), \
    prefix``_bid

`define _AXI4_AR_PAYLOAD(prefix) \
    `_AXI4LITE_AR_PAYLOAD(prefix), \
    `_AXI4_A_EXTRA_SIGS_PAYLOAD(prefix, ar)

`define _AXI4_R_PAYLOAD(prefix) \
    `_AXI4LITE_R_PAYLOAD(prefix), \
    prefix``_rid, \
    prefix``_rlast

// List of AXI4 AW channel payload fields
`define AXI4_AW_PAYLOAD(prefix) {`_AXI4_AW_PAYLOAD(prefix)}

// List of AXI4 W channel payload fields
`define AXI4_W_PAYLOAD(prefix)  {`_AXI4_W_PAYLOAD(prefix)}

// List of AXI4 B channel payload fields
`define AXI4_B_PAYLOAD(prefix)  {`_AXI4_B_PAYLOAD(prefix)}

// List of AXI4 AR channel payload fields
`define AXI4_AR_PAYLOAD(prefix) {`_AXI4_AR_PAYLOAD(prefix)}

// List of AXI4 R channel payload fields
`define AXI4_R_PAYLOAD(prefix)  {`_AXI4_R_PAYLOAD(prefix)}

// Length of AXI4 AW channel payload fields
`define AXI4_AW_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_AW_PAYLOAD_LEN(addr_width, data_width, id_width) + `_AXI4_A_EXTRA_SIGS_PAYLOAD_LEN(id_width))

// Length of AXI4 W channel payload fields
`define AXI4_W_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_W_PAYLOAD_LEN(addr_width, data_width, id_width) + 1)

// Length of AXI4 B channel payload fields
`define AXI4_B_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_B_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width)

// Length of AXI4 AR channel payload fields
`define AXI4_AR_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_AR_PAYLOAD_LEN(addr_width, data_width, id_width) + `_AXI4_A_EXTRA_SIGS_PAYLOAD_LEN(id_width))

// Length of AXI4 R channel payload fields
`define AXI4_R_PAYLOAD_LEN(addr_width, data_width, id_width) \
    (`AXI4LITE_R_PAYLOAD_LEN(addr_width, data_width, id_width) + id_width + 1)
