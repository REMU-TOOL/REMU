TESTS-mem := arsw srsw srsw2 offset chain

VSRC-mem-arsw := mem/arsw.v mem/mem.v
VTOP-mem-arsw := arsw
VSIM-mem-arsw := mem/arswtest.v

VSRC-mem-srsw := mem/srsw.v mem/mem.v
VTOP-mem-srsw := srsw
VSIM-mem-srsw := mem/srswtest.v

VSRC-mem-srsw2 := mem/srsw2.v
VTOP-mem-srsw2 := srsw2
VSIM-mem-srsw2 := mem/srsw2test.v

VSRC-mem-offset := mem/offset.v mem/mem.v
VTOP-mem-offset := offset
VSIM-mem-offset := mem/offsettest.v

VSRC-mem-chain := mem/chain.v mem/mem.v
VTOP-mem-chain := chain
VSIM-mem-chain := mem/chaintest.v
