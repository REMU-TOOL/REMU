import random
import json

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiMaster, AxiRam
from cocotbext.axi.constants import AxiBurstType

CONFIG_FILE = '.build/sysinfo.json'

class TB:
    def __init__(self, dut):
        self.load_config(CONFIG_FILE)
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, 'host_dma'), dut.host_clk, dut.host_rst)
        self.axilite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, 'target_mmio'), dut.target_clk, dut.target_rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'target_dma'), dut.target_clk, dut.target_rst, size=0x1000)
        self.axilite_ram = AxiLitRam(AxiLiteBus.from_prefix(dut, 'host_mmio'), dut.host_clk, dut.host_rst, size=0x1000)


    def load_config(self, path):
        with open(path, 'r') as f:
            self.config = json.load(f)
        self.ff_size = sum([ff['width'] for ff in self.config['scan_ff']])
        self.mem_size = sum([mem['width'] * mem['depth'] for mem in self.config['scan_ram']])

    async def do_reset(self):
        self.dut._log.info("reset asserted")
        self.dut.target_rst.value = 1
        self.dut.host_rst.value = 1
        self.dut.run_mode.value = 1
        self.dut.scan_mode.value = 0
        self.dut.ff_scan.value = 0
        self.dut.ff_dir.value = 0
        self.dut.ff_sdi.value = 0
        self.dut.ram_scan_reset.value = 0
        self.dut.ram_scan.value = 0
        self.dut.ram_dir.value = 0
        self.dut.ram_sdi.value = 0
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.host_rst.value = 0
        await RisingEdge(self.dut.host_clk)
        self.dut._log.info("reset deasserted")

    async def do_save(self):
        ff_data = ''
        ram_data = ''
        self.dut._log.info("save begin")
        while self.dut.idle.value != 1:
            await RisingEdge(self.dut.host_clk)
        self.dut.scan_mode.value = 1
        self.dut.ram_scan_reset.value = 1
        await RisingEdge(self.dut.host_clk)
        self.dut.ram_scan_reset.value = 0
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 0
        for _ in range(self.ff_size):
            await RisingEdge(self.dut.host_clk)
            if self.dut.ff_sdo.value.binstr == '1':
                ff_data += '1'
            else:
                ff_data += '0'
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 0
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        for _ in range(self.mem_size):
            await RisingEdge(self.dut.host_clk)
            if self.dut.ram_sdo.value.binstr == '1':
                ram_data += '1'
            else:
                ram_data += '0'
        self.dut.ram_scan.value = 0
        await RisingEdge(self.dut.host_clk)
        self.dut.scan_mode.value = 0
        self.dut._log.info("save end")
        return ff_data, ram_data

    async def do_load(self, data):
        ff_data, ram_data = data
        self.dut._log.info("load begin")
        while self.dut.idle.value != 1:
            await RisingEdge(self.dut.host_clk)
        self.dut.scan_mode.value = 1
        self.dut.ram_scan_reset.value = 1
        await RisingEdge(self.dut.host_clk)
        self.dut.ram_scan_reset.value = 0
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 1
        for d in ff_data:
            if d == '1':
                self.dut.ff_sdi.value = 1
            else:
                self.dut.ff_sdi.value = 0
            await RisingEdge(self.dut.host_clk)
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 1
        for d in ram_data:
            if d == '1':
                self.dut.ram_sdi.value = 1
            else:
                self.dut.ram_sdi.value = 0
            await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.ram_scan.value = 0
        await RisingEdge(self.dut.host_clk)
        self.dut.scan_mode.value = 0
        self.dut._log.info("load end")

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def read_write_worker_func():
        for step in range(0, 10):
            burst = AxiBurstType.INCR
            size = random.randint(0, 3)
            addr = (2 ** size) * random.randint(0, 16)
            length = 0x100 if burst == AxiBurstType.INCR else 16 * (2 ** size)
            axi_data = bytearray([x % 256 for x in range(length)])
            axilite_data = 123
            dut._log.info("STEP %d: address=0x%x, length=0x%x, axsize=%d axburst=%s" % (step, addr, length, size, burst))
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            await tb.axilite_master.write(addr, axilite_data, size=size)
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            await tb.axi_master.write(addr, axi_data, burst=burst, size=size, awid=0)
            await ClockCycles(dut.host_clk, random.randint(1, 20))
            data_arr = await tb.axi_master.read(addr, length, burst=burst, size=size, arid=0)
            data_lite = await tb.axilite_master.read(addr,size=size)
            assert data_arr.data == axi_data
            assert data_lite == axilite_data

    running = True

    async def pause_resume_worker_func():
        while running:
            await ClockCycles(dut.host_clk, random.randint(100, 1000))
            dut.run_mode.value = 0
            dut._log.info("pause requested")
            while dut.idle.value != 1:
                await RisingEdge(dut.host_clk)
            dut._log.info("pause acknowledged")
            data = await tb.do_save()
            await tb.do_load(data)
            await ClockCycles(dut.host_clk, random.randint(1, 5))
            dut.run_mode.value = 1
            dut._log.info("resumed")

    read_write_worker = cocotb.fork(read_write_worker_func())
    pause_resume_worker = cocotb.fork(pause_resume_worker_func())

    await ClockCycles(dut.host_clk, 100)
    dut._log.info("Releasing DUT reset")
    dut.target_rst.value = 0

    await read_write_worker.join()
    running = False
    await pause_resume_worker.join()

    await RisingEdge(dut.host_clk)
