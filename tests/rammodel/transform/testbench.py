import random
import yaml

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiMaster, AxiRam
from cocotbext.axi.constants import AxiBurstType

CONFIG_FILE = '.build/scanchain.yml'

class TB:
    def __init__(self, dut):
        self.load_config(CONFIG_FILE)
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, 's_axi'), dut.target_clk, dut.target_rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'm_axi'), dut.host_clk, dut.host_rst, size=0x1000)

    def load_config(self, path):
        with open(path, 'r') as f:
            self.config = yaml.load(f, Loader=yaml.Loader)
        mem_width = self.config['mem_width']
        self.ff_size = len(self.config['ff'])
        self.mem_size = sum([x['depth'] * ((x['width'] + mem_width - 1) // mem_width) for x in self.config['mem']])

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
        ff_data = []
        ram_data = []
        self.dut._log.info("save begin")
        self.dut.scan_mode.value = 1
        self.dut.ram_scan_reset.value = 1
        await RisingEdge(self.dut.host_clk)
        self.dut.ram_scan_reset.value = 0
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 0
        for _ in range(self.ff_size):
            await RisingEdge(self.dut.host_clk)
            ff_data.append(self.dut.ff_sdo.value)
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 0
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        for _ in range(self.mem_size):
            await RisingEdge(self.dut.host_clk)
            ram_data.append(self.dut.ram_sdo.value)
        self.dut.ram_scan.value = 0
        await RisingEdge(self.dut.host_clk)
        self.dut.scan_mode.value = 0
        self.dut._log.info("save end")
        return ff_data, ram_data

    async def do_load(self, data):
        ff_data, ram_data = data
        self.dut._log.info("load begin")
        self.dut.scan_mode.value = 1
        self.dut.ram_scan_reset.value = 1
        await RisingEdge(self.dut.host_clk)
        self.dut.ram_scan_reset.value = 0
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 1
        for d in ff_data:
            self.dut.ff_sdi.value = d
            await RisingEdge(self.dut.host_clk)
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 1
        for d in ram_data:
            self.dut.ram_sdi.value = d
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
        for step in range(0, 30):
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
            await ClockCycles(dut.host_clk, random.randint(10, 1000))
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
