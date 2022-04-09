import os
import bisect
import time
import yaml
from io import BytesIO
from shutil import copyfile, copyfileobj
from tarfile import open as tar_open, TarInfo
from typing import IO

class Checkpoint:
    def __init__(self, name: str, write: bool = False):
        mode = 'w:gz' if write else 'r:gz'
        self.__tarfile = tar_open(name, mode)

    def __enter__(self):
        return self

    def __exit__(self, type, value, tb):
        self.close()

    def close(self):
        self.__tarfile.close()

    def read_data(self, name: str):
        io = self.__tarfile.extractfile(name)
        return io.read()

    def write_data(self, name: str, data: bytes):
        info = TarInfo()
        info.name = name
        info.size = len(data)
        info.mtime = time.time()
        self.__tarfile.addfile(info, BytesIO(data))

    def read_file(self, name: str, file: IO[bytes]):
        fileobj = self.__tarfile.extractfile(name)
        copyfileobj(fileobj, file)

    def write_file(self, name: str, size: int, file: IO[bytes]):
        info = TarInfo()
        info.name = name
        info.size = size
        info.mtime = time.time()
        self.__tarfile.addfile(info, file)

    def read_cycle(self):
        return int.from_bytes(self.read_data('cycle'), 'little')

    def write_cycle(self, cycle: int):
        self.write_data('cycle', cycle.to_bytes(8, 'little'))

class CheckpointManager:
    def __init__(self, store_path: str):
        self.__path = store_path
        os.makedirs(store_path, exist_ok=True)
        self.__load_info()

    def __load_info(self):
        try:
            with open(self.__path + '/cpmgr.yml', 'r') as f:
                info = yaml.load(f, Loader=yaml.Loader)
                self.__cycle_list = info['cycles']
        except IOError:
            self.__cycle_list = []

    def __save_info(self):
        with open(self.__path + '/cpmgr.yml', 'w') as f:
            info = {
                'cycles': self.__cycle_list
            }
            yaml.dump(info, f, Dumper=yaml.Dumper)

    def __ckpt_name(self, cycle: int):
        return self.__path + "/%020d.ckpt" % cycle

    def recent_saved_cycle(self, cycle: int):
        i = bisect.bisect_right(self.__cycle_list, cycle)
        if i == 0:
            raise ValueError
        return self.__cycle_list[i-1]

    def open(self, cycle: int):
        if not cycle in self.__cycle_list:
            raise ValueError
        return Checkpoint(self.__ckpt_name(cycle))

    def create(self, cycle: int):
        if not cycle in self.__cycle_list:
            bisect.insort(self.__cycle_list, cycle)
        self.__save_info()
        return Checkpoint(self.__ckpt_name(cycle), True)

    def save_as(self, cycle: int, file: str):
        if not cycle in self.__cycle_list:
            raise ValueError
        copyfile(self.__ckpt_name(cycle), file)
