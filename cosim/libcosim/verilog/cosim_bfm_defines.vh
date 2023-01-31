`ifndef COSIM_BFM_DEFINES_H
`define COSIM_BFM_DEFINES_H
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights reserved by Ando Ki.
//------------------------------------------------------------------------------
// cosim_bfm_packet.h
//------------------------------------------------------------------------------
// 'c/cosim_bfm_defines.h' and 'verilog/cosim_bfm_defines.vh'
//------------------------------------------------------------------------------
// for 'cmd_type' field
`define COSIM_CMD_NULL        'h00  // skip
`define COSIM_CMD_RD_REQ      'h01
`define COSIM_CMD_WR_REQ      'h02
`define COSIM_CMD_RD_RSP      'h05
`define COSIM_CMD_WR_RSP      'h06
`define COSIM_CMD_TERM_REQ    'h08
`define COSIM_CMD_TERM_RSP    'h09
`define COSIM_CMD_GET_GP_REQ  'h11
`define COSIM_CMD_PUT_GP_REQ  'h12
`define COSIM_CMD_GET_GP_RSP  'h15
`define COSIM_CMD_PUT_GP_RSP  'h16
`define COSIM_CMD_GET_IRQ_REQ 'h21
`define COSIM_CMD_GET_IRQ_RSP 'h22

//------------------------------------------------------------------------------
// for 'cmd_ack' field
`define COSIM_CMD_ACK_ERR     'h0
`define COSIM_CMD_ACK_OK      'h1

//------------------------------------------------------------------------------
// for 'data[]' field
`define COSIM_DATA_BNUM       1024// 256-beat * 4-byte

//------------------------------------------------------------------------------
// Revision history:
//
// 2021.07.01: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
`endif
