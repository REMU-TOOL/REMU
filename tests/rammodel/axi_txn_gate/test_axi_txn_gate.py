import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiMaster, AxiRam

class TB:
    def __init__(self, dut):
        self.dut = dut
        cocotb.fork(Clock(dut.clk, 10, units='ns').start())
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, 's_dut'), dut.dut_clk, dut.resetn, reset_active_level=False)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'm_dram'), dut.clk, dut.resetn, reset_active_level=False, size=0x10000)

    async def do_reset(self):
        self.dut._log.info("resetn asserted")
        self.dut.pause.value = 0
        self.dut.up_req.value = 0
        self.dut.down_req.value = 0
        self.dut.resetn.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 1
        await RisingEdge(self.dut.clk)
        self.dut._log.info("resetn deasserted")

    async def do_up(self):
        self.dut._log.info("up requested")
        self.dut.up_req.value = 1
        while self.dut.up.value != 1:
            await RisingEdge(self.dut.clk)
        self.dut.up_req.value = 0
        self.dut._log.info("up acknowledged")

    async def do_down(self):
        self.dut._log.info("down requested")
        self.dut.down_req.value = 1
        while self.dut.down.value != 1:
            await RisingEdge(self.dut.clk)
        self.dut.down_req.value = 0
        self.dut._log.info("down acknowledged")

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def read_write_worker_func():
        step = 0x100
        for addr in range(0, tb.axi_ram.size, step):
            test_data = bytearray([x % 256 for x in range(step)])
            await ClockCycles(dut.clk, random.randint(1, 20))
            await tb.axi_master.write(addr, test_data)
            await ClockCycles(dut.clk, random.randint(1, 20))
            data = await tb.axi_master.read(addr, step)
            assert data.data == test_data

    running = True

    async def pause_resume_worker_func():
        while running:
            await ClockCycles(dut.clk, random.randint(1, 20))
            dut.pause.value = 1
            await ClockCycles(dut.clk, random.randint(1, 3))
            await tb.do_down()
            await ClockCycles(dut.clk, random.randint(1, 5))
            await tb.do_up()
            await ClockCycles(dut.clk, random.randint(1, 3))
            dut.pause.value = 0

    read_write_worker = cocotb.fork(read_write_worker_func())
    pause_resume_worker = cocotb.fork(pause_resume_worker_func())

    await read_write_worker.join()
    running = False
    await pause_resume_worker.join()

    await RisingEdge(dut.clk)
