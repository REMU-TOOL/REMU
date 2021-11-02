import socket

class MonitorBase:
    def __init__(self, host: str, port: int):
        self.__sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.__sock.connect((host, port))
        self.__io = self.__sock.makefile('rwb')

    def writeline(self, s: str):
        self.__io.write(bytes(s + "\n", encoding='ascii'))
        self.__io.flush()

    def readline(self):
        return str(self.__io.readline(), encoding='ascii').strip()

    def writeb(self, b: bytes):
        self.__io.write(b)
        self.__io.flush()

    def readb(self, n: int):
        return self.__io.read(n)

    def close(self):
        self.__io.close()
        if self.__sock:
            self.__sock.close()

class Monitor(MonitorBase):
    def trig(self):
        self.writeline('trig')
        s = self.readline()
        return [int(x) for x in s.split(' ')]

    def step_trig(self):
        return -1 in self.trig()

    def user_trig(self):
        trig_list = self.trig()
        return list(filter((-1).__ne__, trig_list))

    def cycle(self):
        self.writeline('cycle')
        return int(self.readline())

    def set_cycle(self, cycle: int):
        self.writeline('set_cycle %d' % cycle)
        s = self.readline()
        if s == 'ok':
            return True
        else:
            return False

    def run(self, cycles: int):
        self.writeline('run %d' % cycles)
        s = self.readline()
        if s == 'ok':
            return True
        else:
            return False

    def reset(self, value: int):
        self.writeline('reset %d' % value)
        s = self.readline()
        if s == 'ok':
            return True
        else:
            return False

    def loadb(self, data: bytes):
        self.writeline('loadb')
        s = self.readline()
        self.writeb(data)
        s = self.readline()
        if s == 'ok':
            return True
        else:
            return False

    def saveb(self):
        self.writeline('saveb')
        s = self.readline()
        n = int(s)
        return self.readb(n)
