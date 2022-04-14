import asyncio
import bisect

from .config import EmulatorConfig
from .checkpoint import Checkpoint, CheckpointManager
from .monitor import Monitor

class EmulatorEvent:
    def __init__(self, cycle: int):
        self.cycle = cycle

    def __lt__(self, other):
        return self.cycle < other.cycle

    def __gt__(self, other):
        return self.cycle > other.cycle

    async def execute(self, mon: Monitor):
        pass

class ResetEvent(EmulatorEvent):
    def __init__(self, cycle: int, val: int):
        EmulatorEvent.__init__(self, cycle)
        self.__val = val

    async def execute(self, mon: Monitor):
        print(f"[EMU] Cycle {self.cycle}: reset={self.__val}")
        mon.reset = self.__val

class LoadEvent(EmulatorEvent):
    def __init__(self, cycle: int, ckptmgr: CheckpointManager):
        EmulatorEvent.__init__(self, cycle)
        self.__ckptmgr = ckptmgr

    async def execute(self, mon: Monitor):
        print(f"[EMU] Cycle {self.cycle}: load checkpoint begin")
        with self.__ckptmgr.open(self.cycle) as cp:
            await mon.load(cp)
        print(f"[EMU] Cycle {self.cycle}: load checkpoint end")

class SaveEvent(EmulatorEvent):
    def __init__(self, cycle: int, ckptmgr: CheckpointManager):
        EmulatorEvent.__init__(self, cycle)
        self.__ckptmgr = ckptmgr

    async def execute(self, mon: Monitor):
        print(f"[EMU] Cycle {self.cycle}: save checkpoint begin")
        with self.__ckptmgr.open(self.cycle) as cp:
            await mon.save(cp)
        print(f"[EMU] Cycle {self.cycle}: save checkpoint end")

class _InternalEventType:
    pass

class _StartEvent(EmulatorEvent, _InternalEventType):
    async def execute(self, mon: Monitor):
        print(f"[EMU] Cycle {self.cycle}: start emulation")

class _BreakEvent(EmulatorEvent, _InternalEventType):
    async def execute(self, mon: Monitor):
        print(f"[EMU] Cycle {self.cycle}: stop emulation")

class _PeriodicalSaveEvent(SaveEvent, _InternalEventType):
    pass

class Emulator:
    def __init__(self, cfg: EmulatorConfig, ckptmgr: CheckpointManager):
        self.__cfg = cfg
        self.__ckptmgr = ckptmgr
        self.__mon = Monitor(cfg)

        self.checkpoint_period = 100000
        self.__init_mem: dict[str, str] = {}
        self.__init_event_list: list[EmulatorEvent] = []
        self.__event_list: list[EmulatorEvent] = []

        for i in range(32):
            self.__mon.trigger_enable[i] = True

        self.__pc_task = asyncio.create_task(self.__mon.putchar_host())

    def close(self):
        self.__pc_task.cancel()
        self.__mon = None

    def init_mem_add(self, name: str, file: str):
        self.__init_mem[name] = file

    def init_mem_clear(self):
        self.__init_mem.clear()

    def init_event_add(self, event: EmulatorEvent):
        bisect.insort(self.__init_event_list, event)

    def init_event_clear(self):
        self.__init_event_list.clear()

    def __check_user_trig(self):
        triggered = False
        for i in range(32):
            if self.__mon.trigger_status[i] and self.__mon.trigger_enable[i]:
                cycle = self.__mon.cycle
                print(f"[EMU] Cycle {cycle}: user trigger {i} activated at previous cycle")
                triggered = True
        return triggered

    def __event_add(self, event: EmulatorEvent):
        bisect.insort(self.__event_list, event)

    def __event_get(self):
        return self.__event_list[0]

    def __event_pop(self):
        self.__event_list.pop(0)

    def __setup_event_list(self):
        self.__event_list = self.__init_event_list.copy()
        self.__mon.cycle = 0

    async def __event_loop(self):
        dry_run = True
        while True:
            cycle = self.__mon.cycle
            if len(self.__event_list) == 0:
                self.__event_add(EmulatorEvent(cycle + 0xffffffff))

            event = self.__event_get()
            delta = event.cycle - cycle

            if delta < 0:
                raise RuntimeError("negative delta time in event loop")

            if dry_run:
                self.__mon.cycle = event.cycle
            else:
                if delta > 0:
                    await self.__mon.run_for(delta)
                if self.__check_user_trig():
                    break

            self.__event_pop()
            await event.execute(self.__mon)

            if isinstance(event, _InternalEventType):
                if isinstance(event, _StartEvent):
                    dry_run = False
                elif isinstance(event, _BreakEvent):
                    break
                elif isinstance(event, _PeriodicalSaveEvent):
                    self.__event_add(_PeriodicalSaveEvent(event.cycle + self.checkpoint_period, self.__ckptmgr))

    async def run(self, periodical_ckpt=False, timeout=0):
        print("[EMU] Run from initial state")
        await self.__mon.init_state(self.__init_mem)
        self.__setup_event_list()
        self.__event_add(_StartEvent(0))
        if timeout > 0:
            self.__event_add(_BreakEvent(timeout))
        if periodical_ckpt:
            self.__event_add(_PeriodicalSaveEvent(0, self.__ckptmgr))
        await self.__event_loop()

    async def rewind(self, cycle: int):
        print(f"[EMU] Rewind to cycle {cycle}")
        prev = self.__ckptmgr.recent_saved_cycle(cycle)
        self.__setup_event_list()
        self.__event_add(LoadEvent(prev, self.__ckptmgr))
        self.__event_add(_StartEvent(prev))
        if prev != cycle:
            self.__event_add(SaveEvent(cycle, self.__ckptmgr))
        self.__event_add(_BreakEvent(cycle))
        await self.__event_loop()

    async def resume(self, timeout=0):
        cycle = self.__mon.cycle
        self.__event_add(_StartEvent(cycle))
        if timeout > 0:
            self.__event_add(_BreakEvent(cycle + timeout))
        await self.__event_loop()

    async def save(self, file: str):
        self.__ckptmgr.save_as(self.__mon.cycle, file)

    @property
    def cycle(self):
        return self.__mon.cycle
