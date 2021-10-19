TESTS-halt := ff srsw_rdata srsw_raddr

VSRC-halt-ff := halt/ffhalt.v
VTOP-halt-ff := ffhalt
VSIM-halt-ff := halt/ffhalt.v halt/ffhalttest.v

VSRC-halt-srsw_rdata := halt/srsw_rdata.v
VTOP-halt-srsw_rdata := srsw_rdata
VSIM-halt-srsw_rdata := halt/srsw_rdata.v halt/srsw_rdata_test.v

VSRC-halt-srsw_raddr := halt/srsw_raddr.v
VTOP-halt-srsw_raddr := srsw_raddr
VSIM-halt-srsw_raddr := halt/srsw_raddr.v halt/srsw_raddr_test.v
