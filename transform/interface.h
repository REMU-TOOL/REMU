#ifndef _INTERFACE_H_
#define _INTERFACE_H_

#include "kernel/yosys.h"

namespace Emu {
namespace Interface {

USING_YOSYS_NAMESPACE

// fixup_ports must be called after all ports are created
void promote_intf_port(Module *module, std::string name, Wire *wire);

// fixup_ports must be called after all ports are created
Wire *create_intf_port(Module *module, std::string name, int width);

std::vector<Wire *> get_intf_ports(Module *module, std::string name);

// fixup_ports must be called after all ports are unregistered
void unregister_intf_ports(Module *module, std::string name);

} // namespace Interface
} // namespace Emu

#endif // #ifndef _INTERFACE_H_
