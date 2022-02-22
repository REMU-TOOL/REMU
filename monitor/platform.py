import yaml

class AddressRegion:
    def __init__(self, node: dict):
        self.__base     = node['base']
        self.__size     = node['size']
        self.__hwbase   = node['hwbase'] if 'hwbase' in node else node['base']

    @property
    def base(self):
        return self.__base

    @property
    def size(self):
        return self.__size

    @property
    def hwbase(self):
        return self.__hwbase

class PlatformConfig:
    def __init__(self, file):
        with open(file, 'r') as f:
            config = yaml.load(f, Loader=yaml.Loader)
            self.__control  = AddressRegion(config['control'])
            self.__memory   = AddressRegion(config['memory'])

    @property
    def control(self):
        return self.__control

    @property
    def memory(self):
        return self.__memory
