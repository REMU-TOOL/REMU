import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiMaster, AxiRam,AxiLiteBus, AxiLiteMaster, AxiLiteRam
from cocotbext.axi.constants import AxiBurstType

class TB:
    def __init__(self, dut):
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, 'test_host_dma_axi'), dut.host_clk, dut.host_rst)
        self.axilite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, 'test_target_mmio_axi'), dut.target_clk, dut.target_rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'test_target_dma_axi'), dut.target_clk, dut.target_rst, size=0x10000)
        self.axilite_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, 'test_host_mmio_axi'), dut.host_clk, dut.host_rst, size=0x1000)

    async def do_reset(self):
        print("do reset")
        self.dut._log.info("reset asserted")
        self.dut.run_mode.value = 1
        self.dut.target_rst.value = 1
        self.dut.host_rst.value = 1
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.host_rst.value = 0
        self.dut._log.info("reset deasserted")
        await RisingEdge(self.dut.host_clk)

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def axi_read_write_worker_func(addr):
        print("start read & write")
        for step in range(0, 100):
            burst = AxiBurstType.INCR
            size = random.randint(0, 3)
            length = 0x100 if burst == AxiBurstType.INCR else 16 * (2 ** size)
            test_data = bytes([x % 256 for x in range(length)])
            dut._log.info("STEP %d: address=0x%x, length=0x%x, axsize=%d axburst=%s" %
                          (step, addr, length, size, burst))
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            await tb.axi_master.write(addr, test_data, burst=burst, size=size)
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            data = await tb.axi_master.read(addr, length, burst=burst, size=size)
            # dut.log.info("test_data: " + repr(test_data))
            # dut.log.info("data.data: " + repr(data.data))
            assert data.data == test_data
    
    async def axilite_read_write_worker_func(addr):
        for step in range(0, 100):
            size = random.randint(0, 3)
            length = 0
            test_data = bytes(1)
            dut._log.info("STEP %d: address=0x%x" %
                          (step, addr))
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            await tb.axilite_master.write(addr, test_data)
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            data = await tb.axilite_master.read(addr,length=1)
            dut._log.info("test_data: " + repr(test_data))
            dut._log.info("data: " + repr(data))
            assert data.data == test_data

    running = True

    async def pause_resume_worker_func():
        while running:
            await ClockCycles(dut.host_clk, random.randint(1, 500))
            dut.run_mode.value = 0
            dut._log.info("pause requested")
            while dut.idle.value != 1:
                await RisingEdge(dut.host_clk)
            dut._log.info("pause acknowledged")
            await ClockCycles(dut.host_clk, random.randint(1, 5))
            dut.run_mode.value = 1
            dut._log.info("resumed")

    read_write_worker_list = []
    for i in range(2):
        read_write_worker_list.append(cocotb.start_soon(axi_read_write_worker_func(i*0x1000)))
    #   read_write_worker_list.append(cocotb.start_soon(axilite_read_write_worker_func(i*0x100)))
    #pause_resume_worker = cocotb.start_soon(pause_resume_worker_func())


    for i in range(2):
    #    read_write_worker_list.append(cocotb.start_soon(axi_read_write_worker_func(i*0x1000)))
        read_write_worker_list.append(cocotb.start_soon(axilite_read_write_worker_func(i*0x100)))

    await ClockCycles(dut.host_clk, 100)
    dut._log.info("Releasing DUT reset")
    dut.target_rst.value = 0

    for worker in read_write_worker_list:
        await worker.join()
    running = False
    #await pause_resume_worker.join()

    await RisingEdge(dut.host_clk)
