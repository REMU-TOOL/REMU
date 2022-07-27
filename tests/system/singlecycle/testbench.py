import yaml

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiRam, AxiLiteBus, AxiLiteMaster
from cocotbext.axi.constants import AxiBurstType

import logging

CONFIG_FILE = '.build/scanchain.yml'

MODE_CTRL           = 0x000
STEP_CNT            = 0x004
TICK_CNT_LO         = 0x008
TICK_CNT_HI         = 0x00c
SCAN_CTRL           = 0x010
TRIG_STAT_BEGIN     = 0x100
TRIG_EN_BEGIN       = 0x110
RESET_CTRL_BEGIN    = 0x120
SOURCE_CTRL_BEGIN   = 0x800
SINK_CTRL_BEGIN     = 0xc00

MODE_CTRL_RUN_MODE      = (1 << 0)
MODE_CTRL_SCAN_MODE     = (1 << 1)
MODE_CTRL_PAUSE_BUSY    = (1 << 2)
MODE_CTRL_MODEL_BUSY    = (1 << 3)

SCAN_CTRL_RUNNING       = (1 << 0)
SCAN_CTRL_START         = (1 << 0)
SCAN_CTRL_DIRECTION     = (1 << 1)

class TB:
    def __init__(self, dut):
        with open(CONFIG_FILE, 'r') as f:
            self.config = yaml.load(f, Loader=yaml.Loader)
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, 'ctrl_scanchain_dma_axi'), dut.host_clk, dut.host_rst, size=0x10000)
        self.axilite_ctrl = AxiLiteMaster(AxiLiteBus.from_prefix(dut, 'ctrl_bridge_s_axilite'), dut.host_clk, dut.host_rst)
        self.axi_ram.write_if.log.setLevel(logging.WARNING)
        self.axi_ram.read_if.log.setLevel(logging.WARNING)
        self.axilite_ctrl.write_if.log.setLevel(logging.WARNING)
        self.axilite_ctrl.read_if.log.setLevel(logging.WARNING)

    async def do_reset(self):
        self.dut._log.info("reset asserted")
        self.dut.host_rst.value = 1
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut.host_rst.value = 0
        self.dut._log.info("reset deasserted")
        await RisingEdge(self.dut.host_clk)

    async def is_run_mode(self):
        return await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_RUN_MODE

    async def enter_run_mode(self):
        self.dut._log.info("entering run mode")
        val = await self.axilite_ctrl.read_dword(MODE_CTRL)
        await self.axilite_ctrl.write_dword(MODE_CTRL, val | MODE_CTRL_RUN_MODE)
        self.dut._log.info("entering run mode ok")
        await RisingEdge(self.dut.host_clk)

    async def exit_run_mode(self):
        self.dut._log.info("exiting run mode")
        val = await self.axilite_ctrl.read_dword(MODE_CTRL)
        await self.axilite_ctrl.write_dword(MODE_CTRL, val & ~MODE_CTRL_RUN_MODE)
        while await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_PAUSE_BUSY:
            await RisingEdge(self.dut.host_clk)
        self.dut._log.info("exiting run mode ok")
        await RisingEdge(self.dut.host_clk)

    async def is_scan_mode(self):
        return await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_SCAN_MODE

    async def enter_scan_mode(self):
        self.dut._log.info("entering scan mode")
        while await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_MODEL_BUSY:
            await RisingEdge(self.dut.host_clk)
        val = await self.axilite_ctrl.read_dword(MODE_CTRL)
        await self.axilite_ctrl.write_dword(MODE_CTRL, val | MODE_CTRL_SCAN_MODE)
        self.dut._log.info("entering scan mode ok")
        await RisingEdge(self.dut.host_clk)

    async def exit_scan_mode(self):
        self.dut._log.info("exiting scan mode")
        val = await self.axilite_ctrl.read_dword(MODE_CTRL)
        await self.axilite_ctrl.write_dword(MODE_CTRL, val & ~MODE_CTRL_SCAN_MODE)
        self.dut._log.info("exiting scan mode ok")
        await RisingEdge(self.dut.host_clk)

    async def get_tick_count(self):
        val = await self.axilite_ctrl.read_dword(TICK_CNT_LO)
        val |= await self.axilite_ctrl.read_dword(TICK_CNT_HI) << 32
        return val

    async def set_tick_count(self, val: int):
        self.dut._log.info(f"set tick count to {val}")
        await self.axilite_ctrl.write_dword(TICK_CNT_LO, val & 0xffffffff)
        await self.axilite_ctrl.write_dword(TICK_CNT_HI, val >> 32)

    async def set_step_count(self, val: int):
        self.dut._log.info(f"set step count to {val}")
        await self.axilite_ctrl.write_dword(STEP_CNT, val)

    async def do_scan(self, scan_in: bool):
        self.dut._log.info("scan start")
        val = SCAN_CTRL_START
        if scan_in:
            val |= SCAN_CTRL_DIRECTION
        await self.axilite_ctrl.write_dword(SCAN_CTRL, val)
        while await self.axilite_ctrl.read_dword(SCAN_CTRL) & SCAN_CTRL_RUNNING:
            await RisingEdge(self.dut.host_clk)
        self.dut._log.info("scan complete")

    async def get_trig_stat(self, index: int):
        addr = TRIG_STAT_BEGIN + (index // 32) * 4
        offset = index % 32
        return (await self.axilite_ctrl.read_dword(addr) & (1 << offset)) != 0

    async def get_trig_en(self, index: int):
        addr = TRIG_EN_BEGIN + (index // 32) * 4
        offset = index % 32
        return (await self.axilite_ctrl.read_dword(addr) & (1 << offset)) != 0

    async def set_trig_en(self, index: int, enable: bool):
        self.dut._log.info(f"set trigger {index} enable to {enable}")
        addr = TRIG_EN_BEGIN + (index // 32) * 4
        offset = index % 32
        val = await self.axilite_ctrl.read_dword(addr)
        if enable:
            val |= (1 << offset)
        else:
            val &= ~(1 << offset)
        await self.axilite_ctrl.write_dword(addr, val)

    async def set_reset_val(self, index: int, reset: bool):
        self.dut._log.info(f"set reset {index} to {reset}")
        addr = RESET_CTRL_BEGIN + (index // 32) * 4
        offset = index % 32
        val = await self.axilite_ctrl.read_dword(addr)
        if reset:
            val |= (1 << offset)
        else:
            val &= ~(1 << offset)
        await self.axilite_ctrl.write_dword(addr, val)

    async def source_write(self, index: int, chunks: int, val: int):
        addr = SOURCE_CTRL_BEGIN + index * 4
        while await self.axilite_ctrl.read_dword(addr) & 1:
            await RisingEdge(self.dut.host_clk)
        for i in range(chunks):
            await self.axilite_ctrl.write_dword(addr + (i+1)*4, val & 0xffffffff)
            val >>= 32
        await self.axilite_ctrl.write_dword(addr, 0)

    async def source_read(self, index: int, chunks: int):
        addr = SOURCE_CTRL_BEGIN + index * 4
        while await self.axilite_ctrl.read_dword(addr) & 1:
            await RisingEdge(self.dut.host_clk)
        val = 0
        for i in range(chunks):
            val <<= 32
            val |= await self.axilite_ctrl.read_dword(addr + (i+1)*4)
        await self.axilite_ctrl.write_dword(addr, 0)
        return val

    def load_checkpoint_to(self, handle):
        ff_width = self.config['ff_width']
        mem_width = self.config['mem_width']
        if ff_width != 64 or mem_width != 64:
            raise RuntimeError('scanchain width != 64 is currently unsupported')
        addr = 0
        for ff in self.config['ff']:
            slice = self.axi_ram.read_qword(addr)
            addr += 8
            for chunk in ff:
                offset = chunk['offset']
                width = chunk['width']
                if chunk['is_src']:
                    self.dut._log.info(f"loading {chunk['name']} ({offset},{width})")
                    ff_handle = handle._id(chunk['name'], extended=False)
                    value = ff_handle.value
                    mask = ~(~0 << width) << offset
                    value = (slice << offset) & mask | value & ~mask
                    ff_handle.value = value
                slice >>= width
        for mem in self.config['mem']:
            is_src = mem['is_src']
            if is_src:
                self.dut._log.info(f"loading {mem['name']}")
                mem_handle = handle._id(mem['name'], extended=False)
            mem_width = mem['width']
            mem_slices = (mem_width + mem_width - 1) // mem_width
            mem_start_offset = mem['start_offset']
            mask = ~(~0 << mem_width)
            for i in range(mem['depth']):
                value = 0
                for s in range(mem_slices):
                    slice = self.axi_ram.read_qword(addr)
                    addr += 8
                    value |= slice << (mem_width*s)
                value &= mask
                if is_src:
                    mem_handle[mem_start_offset+i].value = value

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    await tb.do_reset()

    await tb.set_trig_en(0, True)
    await tb.set_tick_count(0)

    await tb.set_reset_val(0, True)
    await tb.set_step_count(3)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    await tb.set_reset_val(0, False)
    await tb.enter_run_mode()

    await ClockCycles(dut.host_clk, 100)

    await tb.exit_run_mode()

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")
    saved_tick_count = val

    await tb.enter_scan_mode()
    await tb.do_scan(False)
    await tb.exit_scan_mode()

    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")
    finish_tick_count = val

    await tb.enter_scan_mode()
    await tb.do_scan(True)
    await tb.exit_scan_mode()
    tb.load_checkpoint_to(dut.emu_ref)

    await tb.set_tick_count(saved_tick_count)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    if val != finish_tick_count:
        raise RuntimeError('tick count mismatch')

    await RisingEdge(dut.host_clk)
