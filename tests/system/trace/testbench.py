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

    async def putchar_worker():
        i = 0
        while True:
            val = await tb.sink_read(0, 2)
            dut._log.info(f"trace data = {val}")
            if val != i:
                raise RuntimeError(f'trace data mismatch')
            i += 1

    await tb.do_reset()

    putchar_task = cocotb.fork(putchar_worker())

    await tb.set_trig_en(0, True)
    await tb.set_tick_count(0)

    await tb.set_reset_val(0, True)
    await tb.set_step_count(10)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    await tb.set_reset_val(0, False)
    await tb.set_step_count(200)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    await ClockCycles(dut.host_clk, 1000)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    putchar_task.kill()

    await RisingEdge(dut.host_clk)
