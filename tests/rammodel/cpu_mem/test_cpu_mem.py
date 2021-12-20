import random
import json

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import First, RisingEdge, ClockCycles

CONFIG_FILE = '.build/config.json'

class TB:
    def __init__(self, dut):
        self.dut = dut
        cocotb.fork(Clock(dut.clk, 10, units='ns').start())
        with open(CONFIG_FILE, 'r') as f:
            self.config = json.load(f)
        self.ff_size = self.config['scanchain'][0]['ff_size']
        self.mem_size = self.config['scanchain'][0]['mem_size']

    async def do_reset(self):
        self.dut._log.info("resetn asserted")
        self.dut.do_pause.value = 0
        self.dut.do_resume.value = 0
        self.dut.up_req.value = 0
        self.dut.down_req.value = 0
        self.dut.ff_scan.value = 0
        self.dut.ff_dir.value = 0
        self.dut.ff_sdi.value = 0
        self.dut.ram_scan.value = 0
        self.dut.ram_dir.value = 0
        self.dut.ram_sdi.value = 0
        self.dut.resetn.value = 0
        self.dut.count_write.value = 0
        self.dut.step_write.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 1
        await RisingEdge(self.dut.clk)
        self.dut._log.info("resetn deasserted")

    async def do_pause(self):
        self.dut._log.info("pause")
        self.dut.do_pause.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.do_pause.value = 0

    async def do_resume(self):
        self.dut._log.info("resume")
        self.dut.do_resume.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.do_resume.value = 0

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

    async def do_save(self):
        ff_data = []
        ram_data = []
        self.dut._log.info("save begin")
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 0
        for _ in range(self.ff_size):
            await RisingEdge(self.dut.clk)
            ff_data.append(self.dut.ff_sdo.value)
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        for _ in range(self.mem_size):
            await RisingEdge(self.dut.clk)
            ram_data.append(self.dut.ram_sdo.value)
        self.dut.ram_scan.value = 0
        await RisingEdge(self.dut.clk)
        self.dut._log.info("save end")
        return ff_data, ram_data

    async def do_load(self, data):
        ff_data, ram_data = data
        self.dut._log.info("load begin")
        self.dut.ff_scan.value = 1
        self.dut.ff_dir.value = 1
        for d in ff_data:
            self.dut.ff_sdi.value = d
            await RisingEdge(self.dut.clk)
        self.dut.ff_scan.value = 0
        self.dut.ram_scan.value = 1
        self.dut.ram_dir.value = 1
        for d in ram_data:
            self.dut.ram_sdi.value = d
            await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.ram_scan.value = 0
        await RisingEdge(self.dut.clk)
        self.dut._log.info("load end")

    async def do_count_write(self, count):
        self.dut.count_write.value = 1
        self.dut.count_wdata.value = count
        await RisingEdge(self.dut.clk)
        self.dut.count_write.value = 0

    async def do_step_write(self, step):
        self.dut.step_write.value = 1
        self.dut.step_wdata.value = step
        await RisingEdge(self.dut.clk)
        self.dut.step_write.value = 0

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    async def save_checkpoint():
        await tb.do_down()
        data = await tb.do_save()
        cycle = dut.count.value
        mem = dut.mem.value
        await tb.do_up()
        return data, cycle, mem

    async def load_checkpoint(checkpoint):
        data, cycle, mem = checkpoint
        await tb.do_down()
        await tb.do_load(data)
        await tb.do_count_write(cycle)
        dut.mem.value = mem
        await tb.do_up()

    period = 20000
    checkpoints = []
    trig_cycle = 0
    await tb.do_pause()
    await tb.do_count_write(0)
    while True:
        await tb.do_step_write(period)
        await tb.do_resume()
        await RisingEdge(dut.pause)
        await RisingEdge(dut.clk)
        if dut.trig.value == 1:
            trig_cycle = dut.count.value
            dut._log.info("DUT trigger activated at cycle %d" % trig_cycle)
            await tb.do_step_write(0)
            break
        dut._log.info("save checkpoint")
        checkpoints.append(await save_checkpoint())
        dut._log.info("checkpoint cycle = %d", dut.count.value)

    for checkpoint in checkpoints:
        dut._log.info("load checkpoint")
        await load_checkpoint(checkpoint)
        await tb.do_resume()
        await RisingEdge(dut.pause)
        await RisingEdge(dut.clk)
        cycle = dut.count.value
        dut._log.info("DUT trigger activated at cycle %d" % cycle)
        if (cycle != trig_cycle):
            raise ValueError("cycle mismatch with first run")

    await RisingEdge(dut.clk)
