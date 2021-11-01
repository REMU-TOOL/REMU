from .config import EmulatorConfig
from .checkpoint import CheckpointManager
from .monitor import Monitor

class Emulator:
    def __init__(self, config_file: str, host: str, port: int, checkpoint_path: str = "/tmp/ckpt"):
        self.__config = EmulatorConfig(config_file)
        self.__ckptmgr = CheckpointManager(self.__config, checkpoint_path)
        self.__mon = Monitor(host, port)
        self.checkpoint_period = 100000

    def __enter__(self):
        return self

    def __exit__(self, type, value, tb):
        self.close()

    def close(self):
        self.__mon.close()

    def __check_user_trig(self):
        user_trig = self.__mon.user_trig()
        for trig in user_trig:
            print("User trigger %s activated" % self.__config.trig(trig))
        return len(user_trig) > 0

    def init_load_mem(self, mem: str, file: str):
        with self.__ckptmgr.open_checkpoint(0) as c:
            with open(file, 'rb') as f:
                c.load_mem(mem, f)

    def cycle(self):
        return self.__mon.cycle()

    def reset(self):
        with self.__ckptmgr.open_checkpoint(0) as c:
            self.__mon.loadb(c.read())
        self.__mon.set_cycle(0)
        self.__mon.reset(100) # TODO: parameterize

    def save(self, hex_file: str = None):
        with self.__ckptmgr.open_checkpoint(self.__mon.cycle()) as c:
            c.write(self.__mon.saveb())
            if hex_file:
                with open(hex_file, 'w') as f:
                    c.save_hex(f)

    def rewind(self, cycle: int):
        prev = self.__ckptmgr.recent_saved_cycle(cycle)
        if prev == cycle:
            return
        print("Rewind from cycle %d" % prev)
        with self.__ckptmgr.open_checkpoint(prev) as c:
            self.__mon.loadb(c.read())
        self.__mon.set_cycle(prev)
        print("Run until cycle %d" % cycle)
        self.__mon.run(cycle - prev)

    def run(self, periodical_ckpt=False):
        period = self.checkpoint_period if periodical_ckpt else 0xffffffff
        while True:
            self.__mon.run(period)
            if self.__check_user_trig():
                break
            if periodical_ckpt:
                cycle = self.__mon.cycle()
                print("Checkpoint cycle = %d" % cycle)
                self.save()
