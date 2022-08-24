import sys
sys.path.append('..')
from system_tb import *

WORKLOAD_FILE = '../../../design/picorv32/baremetal.bin'
CONFIG_FILE = '.build/scanchain.yml'

class TB(SystemTB):
    def __init__(self, dut):
        SystemTB.__init__(self, dut, CONFIG_FILE)
        self.axi_target_ram = AxiRam(AxiBus.from_prefix(dut, 'target_uncore_u_rammodel_backend_host_axi'), dut.host_clk, dut.host_rst, size=0x10000000)
        self.axi_target_ram.write_if.log.setLevel(logging.WARNING)
        self.axi_target_ram.read_if.log.setLevel(logging.WARNING)

    async def do_reset(self):
        self.dut._log.info("reset asserted")
        self.sys_reset(1)
        await RisingEdge(self.dut.host_clk)
        await RisingEdge(self.dut.host_clk)
        self.dut._log.info(f"loading workload {WORKLOAD_FILE} into memory")
        with open(WORKLOAD_FILE, 'rb') as f:
            self.axi_target_ram.write(0, f.read())
        self.sys_reset(0)
        self.dut._log.info("reset deasserted")
        await RisingEdge(self.dut.host_clk)

@cocotb.test()
async def run_test(dut):
    tb = TB(dut)

    async def putchar_worker():
        while True:
            val = await tb.sink_read(0, 1)
            sys.stdout.write(chr(val))
            sys.stdout.flush()

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
    await tb.set_step_count(16384)
    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    await tb.enter_scan_mode()
    await tb.do_scan(False)
    await tb.exit_scan_mode()

    saved_tick_count = await tb.get_tick_count()
    dut._log.info(f"current tick count = {saved_tick_count}")
    saved_sc_data = tb.save_checkpoint()

    with open('.build/scanchain', 'wb') as f:
        f.write(saved_sc_data)

    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    finish_tick_count = await tb.get_tick_count()
    dut._log.info(f"current tick count = {finish_tick_count}")

    tb.load_checkpoint(saved_sc_data)
    await tb.set_tick_count(saved_tick_count)

    await tb.enter_scan_mode()
    await tb.do_scan(True)
    await tb.exit_scan_mode()

    await tb.enter_run_mode()

    while await tb.is_run_mode():
        await ClockCycles(dut.host_clk, 10)

    await ClockCycles(dut.host_clk, 100)

    val = await tb.get_tick_count()
    dut._log.info(f"current tick count = {val}")

    if val != finish_tick_count:
        raise RuntimeError('tick count mismatch')

    putchar_task.kill()

    await RisingEdge(dut.host_clk)
