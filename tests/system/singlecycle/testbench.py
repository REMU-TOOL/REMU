import sys
sys.path.append('..')
from system_tb import *

CONFIG_FILE = '.build/scanchain.yml'

class TB(SystemTB):
    def __init__(self, dut):
        SystemTB.__init__(self, dut, CONFIG_FILE)

    async def do_reset(self):
        self.dut._log.info("reset asserted")
        self.sys_reset(1)
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.sys_reset(0)
        self.dut._log.info("reset deasserted")
        await RisingEdge(self.dut.host_clk)

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
    tb.copy_checkpoint_to(dut.emu_ref)

    await tb.set_tick_count(saved_tick_count)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    if val != finish_tick_count:
        raise RuntimeError('tick count mismatch')

    await RisingEdge(dut.host_clk)
