#!/usr/bin/env python3

import argparse
import json
import math
from typing import BinaryIO

class ChunkLoc:
    def __init__(self, addr: int, rel_off: int):
        self.addr = addr
        self.rel_off = rel_off

class MemLoc:
    def __init__(self, addr: int, width: int, depth: int, start_off: int, slices: int):
        self.addr = addr
        self.width = width
        self.depth = depth
        self.start_off = start_off
        self.slices = slices

class ScanChainConfig:
    def __init__(self, config_file: str):
        config = json.load(open(config_file, 'r'))
        self._ff_to_loc:    dict[str, list[ChunkLoc]]   = {}
        self._mem_to_loc:   dict[str, MemLoc]           = {}
        self._chain_width:  int = config['width']
        self._ff_slices:    int = config['ff_size']
        self._mem_slices:   int = config['mem_size']
        self.__init_ff_locs(config)
        self.__init_mem_locs(config)

    def __init_ff_locs(self, config):
        ff_list: dict[str, list[tuple]] = {}
        for ff in config['ff']:
            for src in ff['src']:
                name = src['name']
                if not name in ff_list:
                    ff_list[name] = []
                chunks = ff_list[name]
                chunks.append((
                    src['offset'],
                    src['width'],
                    ff['addr'],
                    src['new_offset']
                ))
        for name, chunks in ff_list.items():
            chunks.sort(key=lambda x: x[0])
            locs: list[ChunkLoc] = []
            pos = 0
            for c in chunks:
                locs += [None] * (c[0] - pos) # pad inaccessible locations
                loc = ChunkLoc(c[2], c[3] - c[0])
                for i in range(c[0], c[0] + c[1]):
                    locs.append(loc)
                pos += c[1] # width
            self._ff_to_loc[name] = locs

    def __init_mem_locs(self, config):
        for mem in config['mem']:
            name = mem['name']
            self._mem_to_loc[name] = MemLoc(
                self._ff_slices + mem['addr'],
                mem['width'],
                mem['depth'],
                mem['start_offset'],
                math.ceil(mem['width'] / self._chain_width)
            )

    def ff_loc(self, name: str):
        return self._ff_to_loc[name]

    def mem_loc(self, name: str):
        return self._mem_to_loc[name]

    @property
    def chain_width(self):
        return self._chain_width

    @property
    def slice_bytes(self):
        return math.ceil(self._chain_width / 8)

    @property
    def total_slices(self):
        return self._ff_slices + self._mem_slices

class Checkpoint:
    def __init__(self, config: ScanChainConfig, checkpoint: BinaryIO):
        self._config = config
        self._checkpoint = checkpoint
        if self._checkpoint.writable():
            self._checkpoint.seek(self._config.total_slices * self._config.slice_bytes)
            self._checkpoint.truncate()
    
    def load_mem(self, name: str, mem: BinaryIO):
        mem_cfg = self._config.mem_loc(name)
        self._checkpoint.seek(mem_cfg.addr * self._config.slice_bytes)
        mem_bytes = math.ceil(mem_cfg.width / 8)
        sc_mask = (1 << self._config.chain_width) - 1
        for _ in range(0, mem_cfg.depth):
            data = int.from_bytes(mem.read(mem_bytes), 'little')
            for _ in range(0, mem_cfg.slices):
                self._checkpoint.write(int.to_bytes(data & sc_mask, self._config.slice_bytes, 'little'))
                data >>= self._config.chain_width

    def save_mem(self, name: str, mem: BinaryIO):
        mem_cfg = self._config.mem_loc(name)
        self._checkpoint.seek(mem_cfg.addr * self._config.slice_bytes)
        mem_bytes = math.ceil(mem_cfg.width / 8)
        for _ in range(0, mem_cfg.depth):
            data = 0
            for _ in range(0, mem_cfg.slices):
                data <<= self._config.chain_width
                data |= int.from_bytes(self._checkpoint.read(self._config.slice_bytes), 'little')
            mem.write(int.to_bytes(data, mem_bytes, 'little'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('config', help='scan chain configuration JSON file')
    parser.add_argument('checkpoint', help='checkpoint file')
    parser.add_argument('--loadmem', nargs=2, metavar=('name', 'file'), action='append', default=[], help='load memory from file to checkpoint')
    parser.add_argument('--savemem', nargs=2, metavar=('name', 'file'), action='append', default=[], help='save memory from checkpoint to file')
    args = parser.parse_args()

    config = ScanChainConfig(args.config)
    cpfile = open(args.checkpoint, 'rb+')
    cp = Checkpoint(config, cpfile)

    for savemem in args.savemem:
        with open(savemem[1], 'wb') as f:
            cp.save_mem(savemem[0], f)

    for loadmem in args.loadmem:
        with open(loadmem[1], 'rb') as f:
            cp.load_mem(loadmem[0], f)

    cpfile.close()
