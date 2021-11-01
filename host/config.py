import json
import math

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

class EmulatorConfig:
    def __init__(self, config_file: str):
        config = json.load(open(config_file, 'r'))
        self.__ff_to_loc:    dict[str, list[ChunkLoc]]   = {}
        self.__mem_to_loc:   dict[str, MemLoc]           = {}
        self.__trig:         list[str]                   = []
        self.__chain_width:  int = config['width']
        self.__ff_slices:    int = config['ff_size']
        self.__mem_slices:   int = config['mem_size']
        self.__init_ff_locs(config)
        self.__init_mem_locs(config)
        self.__init_trig(config)

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
            self.__ff_to_loc[name] = locs

    def __init_mem_locs(self, config):
        for mem in config['mem']:
            name = mem['name']
            self.__mem_to_loc[name] = MemLoc(
                self.__ff_slices + mem['addr'],
                mem['width'],
                mem['depth'],
                mem['start_offset'],
                math.ceil(mem['width'] / self.__chain_width)
            )

    def __init_trig(self, config):
        for trig in config['trigger']:
            self.__trig.append(trig['name'])

    def ff_loc(self, name: str):
        return self.__ff_to_loc[name]

    def mem_loc(self, name: str):
        return self.__mem_to_loc[name]

    def trig(self, id: int):
        return self.__trig[id]

    @property
    def chain_width(self):
        return self.__chain_width

    @property
    def slice_bytes(self):
        return math.ceil(self.__chain_width / 8)

    @property
    def total_slices(self):
        return self.__ff_slices + self.__mem_slices
