TESTS-halt := ff srsw_rdata srsw_raddr

VSRC-halt-ff := ffhalt.v
VTOP-halt-ff := ffhalt
VSIM-halt-ff := ffhalt.v ffhalttest.v

VSRC-halt-srsw_rdata := srsw_rdata.v
VTOP-halt-srsw_rdata := srsw_rdata
VSIM-halt-srsw_rdata := srsw_rdata.v srsw_rdata_test.v

VSRC-halt-srsw_raddr := srsw_raddr.v
VTOP-halt-srsw_raddr := srsw_raddr
VSIM-halt-srsw_raddr := srsw_raddr.v srsw_raddr_test.v
