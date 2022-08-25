from operator import truediv
import yaml

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiRam, AxiLiteBus, AxiLiteMaster

import logging

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

SV_KEYWORDS = ["accept_on", "alias", "always", "always_comb", "always_ff", "always_latch", "and",
    "assert", "assign", "assume", "automatic", "before", "begin", "bind", "bins", "binsof",
    "bit", "break", "buf", "bufif0", "bufif1", "byte", "case", "casex", "casez", "cell",
    "chandle", "checker", "class", "clocking", "cmos", "config", "const", "constraint",
    "context", "continue", "cover", "covergroup", "coverpoint", "cross", "deassign",
    "default", "defparam", "design", "disable", "dist", "do", "edge", "else", "end",
    "endcase", "endchecker", "endclass", "endclocking", "endconfig", "endfunction", "endgenerate",
    "endgroup", "endinterface", "endmodule", "endpackage", "endprimitive", "endprogram",
    "endproperty", "endspecify", "endsequence", "endtable", "endtask", "enum", "event",
    "eventually", "expect", "export", "extends", "extern", "final", "first_match", "for",
    "force", "foreach", "forever", "fork", "forkjoin", "function", "generate", "genvar",
    "global", "highz0", "highz1", "if", "iff", "ifnone", "ignore_bins", "illegal_bins",
    "implements", "implies", "import", "incdir", "include", "initial", "inout", "input",
    "inside", "instance", "int", "integer", "interconnect", "interface", "intersect",
    "join", "join_any", "join_none", "large", "let", "liblist", "library", "local", "localparam",
    "logic", "longint", "macromodule", "matches", "medium", "modport", "module", "nand",
    "negedge", "nettype", "new", "nexttime", "nmos", "nor", "noshowcancelled", "not",
    "notif0", "notif1", "null", "or", "output", "package", "packed", "parameter", "pmos",
    "posedge", "primitive", "priority", "program", "property", "protected", "pull0",
    "pull1", "pulldown", "pullup", "pulsestyle_ondetect", "pulsestyle_onevent", "pure",
    "rand", "randc", "randcase", "randsequence", "rcmos", "real", "realtime", "ref",
    "reg", "reject_on", "release", "repeat", "restrict", "return", "rnmos", "rpmos",
    "rtran", "rtranif0", "rtranif1", "s_always", "s_eventually", "s_nexttime", "s_until",
    "s_until_with", "scalared", "sequence", "shortint", "shortreal", "showcancelled",
    "signed", "small", "soft", "solve", "specify", "specparam", "static", "string", "strong",
    "strong0", "strong1", "struct", "super", "supply0", "supply1", "sync_accept_on",
    "sync_reject_on", "table", "tagged", "task", "this", "throughout", "time", "timeprecision",
    "timeunit", "tran", "tranif0", "tranif1", "tri", "tri0", "tri1", "triand", "trior",
    "trireg", "type", "typedef", "union", "unique", "unique0", "unsigned", "until", "until_with",
    "untyped", "use", "uwire", "var", "vectored", "virtual", "void", "wait", "wait_order",
    "wand", "weak", "weak0", "weak1", "while", "wildcard", "wire", "with", "within",
    "wor", "xnor", "xor"
]

def escape_verilog_id(name: str):
    if name.isidentifier() and not name in SV_KEYWORDS:
        return name
    return '\\' + name + ' '

def hier2flat(path):
    return '.'.join([escape_verilog_id(x) for x in path])

class SystemTB:
    def __init__(self, dut, config_file):
        with open(config_file, 'r') as f:
            self.config = yaml.load(f, Loader=yaml.Loader)
        self.dut = dut
        cocotb.fork(Clock(dut.host_clk, 10, units='ns').start())
        self.axi_sc_ram = AxiRam(AxiBus.from_prefix(dut, 'ctrl_scanchain_dma_axi'), dut.host_clk, dut.host_rst, size=0x10000)
        self.axilite_ctrl = AxiLiteMaster(AxiLiteBus.from_prefix(dut, 'ctrl_bridge_s_axilite'), dut.host_clk, dut.host_rst)
        self.axi_sc_ram.write_if.log.setLevel(logging.WARNING)
        self.axi_sc_ram.read_if.log.setLevel(logging.WARNING)
        self.axilite_ctrl.write_if.log.setLevel(logging.WARNING)
        self.axilite_ctrl.read_if.log.setLevel(logging.WARNING)

    def circuit_info(self, path):
        node = self.config['circuit']
        for name in path:
            subnodes = node['subnodes']
            found = False
            for subnode in subnodes:
                if subnode['name'] == name:
                    node = subnode
                    found = True
                    break
            if not found:
                raise KeyError(f'{name} not found')
        return node

    def sys_reset(self, value):
        self.dut.host_rst.value = value

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
            await ClockCycles(self.dut.host_clk, 100)
        self.dut._log.info("exiting run mode ok")
        await RisingEdge(self.dut.host_clk)

    async def is_scan_mode(self):
        return await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_SCAN_MODE

    async def enter_scan_mode(self):
        self.dut._log.info("entering scan mode")
        while await self.axilite_ctrl.read_dword(MODE_CTRL) & MODE_CTRL_MODEL_BUSY:
            await ClockCycles(self.dut.host_clk, 100)
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
            await ClockCycles(self.dut.host_clk, 100)
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
            await ClockCycles(self.dut.host_clk, 100)
        for i in range(chunks):
            await self.axilite_ctrl.write_dword(addr + (i+1)*4, val & 0xffffffff)
            val >>= 32
        await self.axilite_ctrl.write_dword(addr, 0)

    async def sink_read(self, index: int, chunks: int):
        addr = SINK_CTRL_BEGIN + index * 4
        while await self.axilite_ctrl.read_dword(addr) & 1:
            await ClockCycles(self.dut.host_clk, 100)
        await self.axilite_ctrl.write_dword(addr, 0)
        val = 0
        for i in range(chunks):
            val |= await self.axilite_ctrl.read_dword(addr + (i+1)*4) << (32*i)
        return val

    def save_checkpoint(self):
        ff_chain_width = self.config['ff_width']
        mem_chain_width = self.config['mem_width']
        if ff_chain_width != 64 or mem_chain_width != 64:
            raise RuntimeError('scanchain width != 64 is currently unsupported')
        size = len(self.config['ff']) * 8
        for mem in self.config['mem']:
            mem_info = self.circuit_info(mem['name'])
            mem_width = mem_info['width']
            mem_slices = (mem_width + mem_chain_width - 1) // mem_chain_width
            size += mem_info['depth'] * mem_slices * 8
        return self.axi_sc_ram.read(0, size)

    def load_checkpoint(self, data):
        self.axi_sc_ram.write(0, data)

    def copy_checkpoint_to(self, handle):
        ff_chain_width = self.config['ff_width']
        mem_chain_width = self.config['mem_width']
        if ff_chain_width != 64 or mem_chain_width != 64:
            raise RuntimeError('scanchain width != 64 is currently unsupported')
        addr = 0
        for ff in self.config['ff']:
            slice = self.axi_sc_ram.read_qword(addr)
            addr += 8
            for chunk in ff:
                offset = chunk['offset']
                width = chunk['width']
                if chunk['is_src']:
                    name = hier2flat(chunk['name'])
                    self.dut._log.info(f"loading {name} ({offset},{width})")
                    ff_handle = handle._id(name, extended=False)
                    value = ff_handle.value
                    mask = ~(~0 << width) << offset
                    value = (slice << offset) & mask | value & ~mask
                    ff_handle.value = value
                slice >>= width
        for mem in self.config['mem']:
            is_src = mem['is_src']
            if is_src:
                name = hier2flat(mem['name'])
                self.dut._log.info(f"loading {name}")
                mem_handle = handle._id(name, extended=False)
            mem_info = self.circuit_info(mem['name'])
            mem_width = mem_info['width']
            mem_slices = (mem_width + mem_chain_width - 1) // mem_chain_width
            mem_start_offset = mem_info['start_offset']
            mask = ~(~0 << mem_width)
            for i in range(mem_info['depth']):
                value = 0
                for s in range(mem_slices):
                    slice = self.axi_sc_ram.read_qword(addr)
                    addr += 8
                    value |= slice << (mem_chain_width*s)
                value &= mask
                if is_src:
                    mem_handle[mem_start_offset+i].value = value
