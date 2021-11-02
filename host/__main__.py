import argparse

from host import config

from . import Emulator

class EmulatorMain:
    def __init__(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('config', help='scan chain configuration JSON file')
        parser.add_argument('host', help='monitor address')
        parser.add_argument('port', help='monitor port', type=int)
        parser.add_argument('checkpoint', help='checkpoint storage path')
        parser.add_argument('--loadmem', nargs=2, metavar=('name', 'file'), action='append', default=[], help='load memory from file for initialization')
        parser.add_argument('--period', metavar='cycle', type=int, action='store', default=100000, help='set checkpoint period')
        parser.add_argument('--dump', metavar='cycle', type=int, action='store', help='dump checkpoint at specified cycle')
        parser.add_argument('--dumpfile', metavar='file', action='store', help='specify dump file name (valid only if --dump is specified)')
        args = parser.parse_args()
        self.__emu = Emulator(args.config, args.host, args.port, args.checkpoint)
        self.__emu.checkpoint_period = args.period
        for loadmem in args.loadmem:
            self.__emu.init_load_mem(loadmem[0], loadmem[1])
        self.__dump = args.dump
        self.__dumpfile = args.dumpfile

    def run(self):
        if self.__dump:
            self.__emu.rewind(self.__dump)
            self.__emu.save(self.__dumpfile)
        else:
            self.__emu.run(True)

    def close(self):
        self.__emu.close()

if __name__ == '__main__':
    emu = EmulatorMain()
    emu.run()
    emu.close()
