#ifndef _DESIGNTOOLS_H_
#define _DESIGNTOOLS_H_

#include "kernel/yosys.h"
#include "kernel/celltypes.h"
#include "kernel/modtools.h"

#include <sstream>

namespace Emu {

USING_YOSYS_NAMESPACE

class VerilogIdEscape {
    static const pool<std::string> keywords;
public:
    std::string operator()(const std::string &name);
};

extern class VerilogIdEscape VerilogIdEscape;

struct SigMapCache {
    dict<Module*, SigMap> module_sigmap;

    SigMap &operator[](Module *module) {
        if (!module_sigmap.count(module))
            module_sigmap.insert({module, SigMap(module)});
        return module_sigmap.at(module);
    }
};

struct ModWalkerCache {
    dict<Module*, ModWalker> module_walker;

    ModWalker &operator[](Module *module) {
        if (!module_walker.count(module))
            module_walker.insert({module, ModWalker(module->design, module)});
        return module_walker.at(module);
    }
};

// Hierarchy representation for a uniquified design

class DesignInfo {

public:

    using Path = std::vector<Module *>;

    struct PortBit {
        Cell *cell;
        IdString port;
        int offset;

        bool operator<(const PortBit &other) const {
            if (cell != other.cell)
                return cell < other.cell;
            if (port != other.port)
                return port < other.port;
            return offset < other.offset;
        }

        bool operator==(const PortBit &other) const {
            return cell == other.cell && port == other.port && offset == other.offset;
        }

        unsigned int hash() const {
            return mkhash_add(mkhash(cell->name.hash(), port.hash()), offset);
        }
    };

private:

    Design *design_;
    Module *top_;
    dict<Module *, Cell *> inst_dict;
    dict<Module *, pool<Module *>> children_dict;

    CellTypes ct;
    SigMap sigmap;
    dict<SigBit, pool<PortBit>> signal_drivers;
    dict<SigBit, pool<PortBit>> signal_consumers;

    CellTypes comb_cell_types;

    void setup();

public:

    Design *design() const { return design_; }
    Module *top() const { return top_; }

    Cell *instance_of(Module *module) const {
        return inst_dict.at(module);
    }

    const pool<Module *> &children_of(Module *module) const {
        return children_dict.at(module);
    }

    Path path_of(Module *mod) const;

    Path path_of(Cell *cell) const {
        return path_of(cell->module);
    }

    Path path_of(Wire *wire) const {
        return path_of(wire->module);
    }

    std::string name_of(IdString &id) const {
        std::string name = id[0] == '\\' ? id.substr(1) : id.str();
        return VerilogIdEscape(name);
    }

    std::vector<std::string> scope_of(Module *mod) const;

    std::string full_name_of(Module *mod) const {
        std::ostringstream ss;
        bool is_first = true;
        for (std::string name : scope_of(mod)) {
            if (is_first)
                is_first = false;
            else
                ss << ".";
            ss << name;
        }
        return ss.str();
    }

    template <typename T>
    std::string full_name_of(T *obj) const {
        std::ostringstream ss;
        ss << full_name_of(obj->module) << "." << name_of(obj->name);
        return ss.str();
    }

    std::string full_name_of(SigBit bit) const {
        if (bit.is_wire()) {
            std::ostringstream ss;
            ss << full_name_of(bit.wire) << "[" << bit.offset << "]";
            return ss.str();
        }
        else 
            return Const(bit.data).as_string();
    }

    pool<PortBit> get_drivers(SigBit bit) const {
        sigmap.apply(bit);
        if (signal_drivers.count(bit) > 0)
            return signal_drivers.at(bit);
        else
            return {};
    }

    pool<PortBit> get_consumers(SigBit bit) const {
        sigmap.apply(bit);
        if (signal_consumers.count(bit) > 0)
            return signal_consumers.at(bit);
        else
            return {};
    }

    // Find signals in candidate (if not empty) list combinationally depended on by target list
    pool<SigBit> find_dependencies(pool<SigBit> target, pool<SigBit> candidate);

    DesignInfo(Design *design) : design_(design), top_(design->top_module()) {
        setup();
    }

};

// Hierarchical connection builder

struct HierconnBuilder {
    DesignInfo &designinfo;
    void connect(Wire *lhs, Wire *rhs);
    HierconnBuilder(DesignInfo &info) : designinfo(info) {}
};

} // namespace Emu

#endif // #ifndef _DESIGNTOOLS_H_
