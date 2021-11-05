TESTS-pause := ff srsw_rdata srsw_raddr

VSRC-pause-ff := pause/ffpause.v
VTOP-pause-ff := ffpause
VSIM-pause-ff := pause/ffpause.v pause/ffpausetest.v

VSRC-pause-srsw_rdata := pause/srsw_rdata.v
VTOP-pause-srsw_rdata := srsw_rdata
VSIM-pause-srsw_rdata := pause/srsw_rdata.v pause/srsw_rdata_test.v

VSRC-pause-srsw_raddr := pause/srsw_raddr.v
VTOP-pause-srsw_raddr := srsw_raddr
VSIM-pause-srsw_raddr := pause/srsw_raddr.v pause/srsw_raddr_test.v
