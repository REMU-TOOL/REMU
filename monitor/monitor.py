import sys
import asyncio

from .platform import PlatformConfig
from .devmem import DevMem
from .control import Controller
from .utils import *

class TriggerEnableProperty:
    def __init__(self, ctrl: Controller):
        self.__ctrl = ctrl

    def __getitem__(self, key: int):
        return get_bit(self.__ctrl.trig_en, key)

    def __setitem__(self, key: int, value: bool):
        value = set_bit(self.__ctrl.trig_en, key, set)
        self.__ctrl.trig_en = value

class TriggerStatusProperty:
    def __init__(self, ctrl: Controller):
        self.__ctrl = ctrl

    def __getitem__(self, key: int):
        return get_bit(self.__ctrl.trig_stat, key)

class Monitor:
    def __init__(self, platcfg: PlatformConfig):
        self.__platcfg = platcfg
        self.__ctrl = Controller(platcfg)
        self.__mem = DevMem(platcfg.memory.base, platcfg.memory.size)
        self.__trigger_enable = TriggerEnableProperty(self.__ctrl)
        self.__trigger_status = TriggerStatusProperty(self.__ctrl)

        self.__ctrl.pause = True
        self.__ctrl.up_req = False
        self.__ctrl.down_req = False

    @property
    def cycle(self) -> int:
        return self.__ctrl.cycle

    @cycle.setter
    def cycle(self, value: int):
        self.__ctrl.cycle = value

    @property
    def reset(self) -> bool:
        return self.__ctrl.reset

    @reset.setter
    def reset(self, value: bool):
        self.__ctrl.reset = value

    @property
    def trigger_enable(self):
        return self.__trigger_enable

    @property
    def trigger_status(self):
        return self.__trigger_status

    @property
    def up(self):
        return self.__ctrl.up_stat

    @property
    def down(self):
        return self.__ctrl.down_stat

    async def run_for(self, cycle: int, ignore_trig: bool = False):
        old_trig_en = self.__ctrl.trig_en
        if ignore_trig:
            self.__ctrl.trig_en = 0

        self.__ctrl.step = cycle
        self.__ctrl.pause = False

        while not self.__ctrl.pause:
            await asyncio.sleep(0.1)

        self.__ctrl.trig_en = old_trig_en

    async def go_up(self):
        self.__ctrl.up_req = True
        while not self.__ctrl.up_stat:
            await asyncio.sleep(0.1)
        self.__ctrl.up_req = False

    async def go_down(self):
        self.__ctrl.down_req = True
        while not self.__ctrl.down_stat:
            await asyncio.sleep(0.1)
        self.__ctrl.down_req = False

    async def __dma_transfer(self, dma_addr: int, load: bool):
        self.__ctrl.dma_addr = dma_addr
        self.__ctrl.dma_dir = load
        self.__ctrl.dma_start = True
        while self.__ctrl.dma_running:
            await asyncio.sleep(0.1)

    async def sc_save(self, buff_off: int):
        size = self.__ctrl.ckpt_size
        if buff_off < 0 or buff_off + size > self.__platcfg.memory.size:
            raise ValueError

        await self.__dma_transfer(
            self.__platcfg.memory.hwbase + buff_off,
            False
        )

        return self.__mem.read_bytes(buff_off, size)

    async def sc_load(self, data: bytes, buff_off: int):
        size = self.__ctrl.ckpt_size
        if len(data) != size:
            raise ValueError
        if buff_off < 0 or buff_off + size > self.__platcfg.memory.size:
            raise ValueError

        self.__mem.write_bytes(buff_off, data)

        await self.__dma_transfer(
            self.__platcfg.memory.hwbase + buff_off,
            True
        )

    async def putchar_host(self):
        while True:
            value = self.__ctrl.putchar
            if (value & (1 << 31)) != 0:
                char = value & 0xff
                sys.stdout.write(chr(char))
                sys.stdout.flush()
            else:
                await asyncio.sleep(0.1)
