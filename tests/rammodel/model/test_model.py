import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiMaster, AxiRam
from cocotbext.axi.constants import AxiBurstType

class TB:
    def __init__(self, dut):
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, 's_axi'), dut.target_clk, dut.target_rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'host_axi'), dut.host_clk, dut.host_rst, size=0x1000)
        self.axi_lsu_ram = AxiRam(AxiBus.from_prefix(dut, 'lsu_axi'), dut.host_clk, dut.host_rst, size=0x2000)

    async def do_reset(self):
        self.dut._log.info("reset asserted")
        self.dut.pause.value = 0
        self.dut.up_req.value = 0
        self.dut.down_req.value = 0
        self.dut.target_rst.value = 1
        self.dut.host_rst.value = 1
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.host_rst.value = 0
        self.dut._log.info("reset deasserted")
        await RisingEdge(self.dut.host_clk)

    async def do_up(self):
        self.dut._log.info("up requested")
        self.dut.up_req.value = 1
        while self.dut.up.value != 1:
            await RisingEdge(self.dut.host_clk)
        self.dut.up_req.value = 0
        self.dut._log.info("up acknowledged")

    async def do_down(self):
        self.dut._log.info("down requested")
        self.dut.down_req.value = 1
        while self.dut.down.value != 1:
            await RisingEdge(self.dut.host_clk)
        self.dut.down_req.value = 0
        self.dut._log.info("down acknowledged")

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def read_write_worker_func():
        for step in range(0, 100):
            burst = random.choice((AxiBurstType.INCR, AxiBurstType.WRAP))
            size = random.randint(0, 3)
            addr = (2 ** size) * random.randint(0, 16)
            length = 0x100 if burst == AxiBurstType.INCR else 16 * (2 ** size)
            test_data = bytearray([x % 256 for x in range(length)])
            dut._log.info("STEP %d: address=0x%x, length=0x%x, axsize=%d axburst=%s" % (step, addr, length, size, burst))
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            await tb.axi_master.write(addr, test_data, burst=burst, size=size, awid=0)
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            data = await tb.axi_master.read(addr, length, burst=burst, size=size, arid=0)
            assert data.data == test_data

    running = True

    async def pause_resume_worker_func():
        while running:
            await ClockCycles(dut.host_clk, random.randint(1, 500))
            dut.pause.value = 1
            await ClockCycles(dut.host_clk, random.randint(1, 3))
            await tb.do_down()
            await ClockCycles(dut.host_clk, random.randint(1, 5))
            await tb.do_up()
            await ClockCycles(dut.host_clk, random.randint(1, 3))
            dut.pause.value = 0

    #read_write_worker = cocotb.fork(read_write_worker_func())
    #pause_resume_worker = cocotb.fork(pause_resume_worker_func())

    await ClockCycles(dut.host_clk, 100)
    dut._log.info("Releasing DUT reset")
    dut.target_rst.value = 0

    read_write_worker = cocotb.fork(read_write_worker_func())
    pause_resume_worker = cocotb.fork(pause_resume_worker_func())

    await read_write_worker.join()
    running = False
    await pause_resume_worker.join()

    await RisingEdge(dut.host_clk)
