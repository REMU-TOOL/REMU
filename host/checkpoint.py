import os
import math
import bisect
import re
from glob import glob
from .config import EmulatorConfig
from typing import BinaryIO, TextIO

class Checkpoint:
    def __init__(self, config: EmulatorConfig, checkpoint: BinaryIO):
        self.__config = config
        self.__checkpoint = checkpoint

    def __enter__(self):
        return self

    def __exit__(self, type, value, tb):
        self.close()

    def close(self):
        self.__checkpoint.close()

    def read(self):
        self.__checkpoint.seek(0)
        return self.__checkpoint.read()

    def write(self, data: bytes):
        self.__checkpoint.seek(0)
        self.__checkpoint.write(data)

    def load_mem(self, name: str, mem: BinaryIO):
        mem_cfg = self.__config.mem_loc(name)
        self.__checkpoint.seek(mem_cfg.addr * self.__config.slice_bytes)
        mem_bytes = math.ceil(mem_cfg.width / 8)
        sc_mask = (1 << self.__config.chain_width) - 1
        for _ in range(0, mem_cfg.depth):
            data = int.from_bytes(mem.read(mem_bytes), 'little')
            for _ in range(0, mem_cfg.slices):
                self.__checkpoint.write(int.to_bytes(data & sc_mask, self.__config.slice_bytes, 'little'))
                data >>= self.__config.chain_width

    def save_mem(self, name: str, mem: BinaryIO):
        mem_cfg = self.__config.mem_loc(name)
        self.__checkpoint.seek(mem_cfg.addr * self.__config.slice_bytes)
        mem_bytes = math.ceil(mem_cfg.width / 8)
        for _ in range(0, mem_cfg.depth):
            data = 0
            for _ in range(0, mem_cfg.slices):
                data <<= self.__config.chain_width
                data |= int.from_bytes(self.__checkpoint.read(self.__config.slice_bytes), 'little')
            mem.write(int.to_bytes(data, mem_bytes, 'little'))

    def save_hex(self, out: TextIO):
        self.__checkpoint.seek(0)
        for _ in range(0, self.__config.total_slices):
            data = bytearray(self.__checkpoint.read(self.__config.slice_bytes))
            data.reverse()
            out.write(data.hex())
            out.write("\n")

class CheckpointManager:
    def __init__(self, config: EmulatorConfig, store_path: str):
        self.__path = store_path
        os.makedirs(store_path, exist_ok=True)
        self.__config = config
        self.__cycle_list = []
        self.__find_ckpts()

    def __find_ckpts(self):
        for name in glob(self.__path + '/*.ckpt.bin'):
            m = re.search(r'/([0-9]+)\.ckpt\.bin', name)
            if m:
                cycle = int(m.group(1))
                if not cycle in self.__cycle_list:
                    bisect.insort(self.__cycle_list, cycle)

    def __ckpt_name(self, cycle: int):
        return self.__path + "/%020d.ckpt.bin" % cycle

    def recent_saved_cycle(self, cycle: int):
        i = bisect.bisect_right(self.__cycle_list, cycle)
        if i:
            return self.__cycle_list[i-1]
        else:
            return 0

    def open_checkpoint(self, cycle: int):
        if not cycle in self.__cycle_list:
            bisect.insort(self.__cycle_list, cycle)
            cpfile = open(self.__ckpt_name(cycle), "wb")
            cpfile.seek(self.__config.total_slices * self.__config.slice_bytes)
            cpfile.truncate()
            cpfile.close()
        cpfile = open(self.__ckpt_name(cycle), "rb+")
        return Checkpoint(self.__config, cpfile)

    @property
    def config(self):
        return self.__config
