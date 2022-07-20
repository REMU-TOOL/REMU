import random
import yaml

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

from cocotbext.axi import AxiBus, AxiMaster, AxiRam
from cocotbext.axi.constants import AxiBurstType

import logging

CONFIG_FILE = '.build/scanchain.yml'
INITMEM_FILE = '../../../design/picorv32/baremetal.bin'

class TB:
    def __init__(self, dut):
        self.load_config(CONFIG_FILE)
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'host_axi'), dut.host_clk, dut.host_rst, size=0x10000)
        self.axi_ram.write_if.log.setLevel(logging.WARNING)
        self.axi_ram.read_if.log.setLevel(logging.WARNING)
        with open(INITMEM_FILE, 'rb') as f:
            self.axi_ram.write(0, f.read())

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
        self.dut.do_pause.value = 0
        self.dut.do_resume.value = 0
        self.dut.count_write.value = 0
        self.dut.step_write.value = 0
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.host_rst.value = 0
        self.dut.target_rst.value = 0
        await RisingEdge(self.dut.host_clk)
        self.dut._log.info("reset deasserted")

    async def do_pause(self):
        self.dut.do_pause.value = 1
        self.dut._log.info("pause requested")
        while self.dut.run_mode.value != 0:
            await RisingEdge(self.dut.host_clk)
        self.dut._log.info("pause acknowledged")
        self.dut.do_pause.value = 0

    async def do_resume(self):
        self.dut._log.info("resume")
        self.dut.do_resume.value = 1
        await RisingEdge(self.dut.host_clk)
        self.dut.do_resume.value = 0

    async def do_save(self):
        ff_data = []
        ram_data = []
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
        while self.dut.idle.value != 1:
            await RisingEdge(self.dut.host_clk)
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

    async def do_count_write(self, count):
        self.dut.count_write.value = 1
        self.dut.count_wdata.value = count
        await RisingEdge(self.dut.host_clk)
        self.dut.count_write.value = 0

    async def do_step_write(self, step):
        self.dut.step_write.value = 1
        self.dut.step_wdata.value = step
        await RisingEdge(self.dut.host_clk)
        self.dut.step_write.value = 0

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def save_checkpoint():
        data = await tb.do_save()
        cycle = dut.count.value
        mem = tb.axi_ram.read(0, None)
        dut.run_mode.value = 1
        dut._log.info("resumed")
        return data, cycle, mem

    async def load_checkpoint(checkpoint):
        data, cycle, mem = checkpoint
        await tb.do_load(data)
        await tb.do_count_write(cycle)
        tb.axi_ram.write(0, mem)

    checkpoints = []
    trig_cycle = 0
    await tb.do_pause()
    await tb.do_count_write(0)
    while True:
        await tb.do_step_write(random.randint(2000, 5000))
        await tb.do_resume()
        await FallingEdge(dut.run_mode)
        await RisingEdge(dut.host_clk)
        if dut.trig.value == 1:
            trig_cycle = dut.count.value
            dut._log.info("DUT trigger activated at cycle %d" % trig_cycle)
            await tb.do_step_write(0)
            break
        dut._log.info("save checkpoint")
        checkpoints.append(await save_checkpoint())
        await RisingEdge(dut.host_clk)
        dut._log.info("checkpoint cycle = %d", dut.count.value)

    for checkpoint in checkpoints:
        dut._log.info("load checkpoint")
        await load_checkpoint(checkpoint)
        await RisingEdge(dut.host_clk)
        dut._log.info("checkpoint cycle = %d", dut.count.value)
        await tb.do_resume()
        await FallingEdge(dut.run_mode)
        await RisingEdge(dut.host_clk)
        cycle = dut.count.value
        dut._log.info("DUT trigger activated at cycle %d" % cycle)
        if (cycle != trig_cycle):
            raise ValueError("cycle mismatch with first run")

    await RisingEdge(dut.host_clk)
