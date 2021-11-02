import bisect
from .config import EmulatorConfig
from .checkpoint import CheckpointManager
from .monitor import Monitor

class EmulatorEvent:
    def __init__(self, cycle: int, callback, param):
        self.__cycle = cycle
        self.__callback = callback
        self.__param = param

    def __lt__(self, other):
        return self.__cycle < other.cycle

    def __gt__(self, other):
        return self.__cycle > other.cycle

    def execute(self):
        if self.__callback:
            self.__callback(self.__cycle, self.__param)

    @property
    def cycle(self):
        return self.__cycle

class Emulator:
    def __init__(self, config_file: str, host: str, port: int, checkpoint_path: str):
        self.__config = EmulatorConfig(config_file)
        self.__ckptmgr = CheckpointManager(self.__config, checkpoint_path)
        self.__mon = Monitor(host, port)
        self.checkpoint_period = 100000
        self.__event_list: list[EmulatorEvent] = []
        self.__run_flag: bool = False
        self.__dry_run: bool = False

    def __enter__(self):
        return self

    def __exit__(self, type, value, tb):
        self.close()

    def __add_event(self, event: EmulatorEvent):
        bisect.insort(self.__event_list, event)

    def __reset_callback(self, cycle, param):
        print("Cycle %d: reset=%d" % (cycle, param))
        self.__mon.reset(param)

    def __break_callback(self, cycle, param):
        print("Cycle %d: break" % cycle)
        self.__run_flag = False

    def __load_callback(self, cycle, param):
        print("Cycle %d: load checkpoint" % cycle)
        with self.__ckptmgr.open_checkpoint(cycle) as c:
            self.__mon.loadb(c.read())
        self.__mon.set_cycle(cycle)
        self.__dry_run = False

    def __ckpt_callback(self, cycle, param):
        print("Cycle %d: save checkpoint" % cycle)
        self.save()
        self.__add_event(EmulatorEvent(cycle + self.checkpoint_period, self.__ckpt_callback, None))

    def __check_user_trig(self):
        user_trig = self.__mon.user_trig()
        if len(user_trig) > 0:
            cycle = self.__mon.cycle()
            for trig in user_trig:
                print("Cycle %d: User trigger %s activated" % (cycle, self.__config.trig(trig)))
            return True
        return False

    def __init(self):
        self.__event_list = []
        self.__add_event(EmulatorEvent(0, self.__reset_callback, 1))
        self.__add_event(EmulatorEvent(100, self.__reset_callback, 0))
        self.__mon.set_cycle(0)
        self.__dry_run = True

    def __run(self):
        self.__run_flag = True
        while self.__run_flag:
            if len(self.__event_list) == 0:
                self.__event_list.append(EmulatorEvent(0xffffffff, None, None))
            new_cycle = self.__event_list[0].cycle
            delta = new_cycle - self.__mon.cycle()
            if self.__dry_run:
                self.__mon.set_cycle(new_cycle)
            else:
                if delta > 0:
                    self.__mon.run(delta)
                if self.__check_user_trig():
                    break
            event = self.__event_list.pop(0)
            event.execute()

    def run(self, periodical_ckpt=False):
        self.__init()
        self.__add_event(EmulatorEvent(0, self.__load_callback, None))
        if periodical_ckpt:
            self.__add_event(EmulatorEvent(self.checkpoint_period, self.__ckpt_callback, None))
        self.__run()

    def rewind(self, cycle: int):
        prev = self.__ckptmgr.recent_saved_cycle(cycle)
        self.__init()
        self.__add_event(EmulatorEvent(prev, self.__load_callback, None))
        self.__add_event(EmulatorEvent(cycle, self.__break_callback, None))
        self.__run()

    def init_load_mem(self, mem: str, file: str):
        with self.__ckptmgr.open_checkpoint(0) as c:
            with open(file, 'rb') as f:
                c.load_mem(mem, f)

    def cycle(self):
        return self.__mon.cycle()

    def save(self, hex_file: str = None):
        with self.__ckptmgr.open_checkpoint(self.__mon.cycle()) as c:
            c.write(self.__mon.saveb())
            if hex_file:
                with open(hex_file, 'w') as f:
                    c.save_hex(f)

    def close(self):
        self.__mon.close()
