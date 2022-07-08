#ifndef _DESIGNTOOLS_H_
#define _DESIGNTOOLS_H_

#include "kernel/yosys.h"
#include "kernel/celltypes.h"

#include <sstream>

namespace Emu {

USING_YOSYS_NAMESPACE

class VerilogIdEscape {
    static const pool<std::string> keywords;
public:
    std::string operator()(const std::string &name);
};

extern class VerilogIdEscape VerilogIdEscape;

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

public:

    void setup(Design *design);

    Design *design() const { return design_; }
    Module *top() const { return top_; }

    Cell *instance_of(Module *module) const {
        return inst_dict.at(module);
    }

    const pool<Module *> &children_of(Module *module) const {
        return children_dict.at(module);
    }

    Path path_of(Module *mod, Module *scope = nullptr) const;

    Path path_of(Cell *cell, Module *scope = nullptr) const {
        return path_of(cell->module, scope);
    }

    Path path_of(Wire *wire, Module *scope = nullptr) const {
        return path_of(wire->module, scope);
    }

    std::string name_of(const IdString &id) const {
        std::string name = id[0] == '\\' ? id.substr(1) : id.str();
        // since Yosys names an element inside a genblk with
        // both names in an escaped identifier ("\\genblk1.xxx")
        // use of VerilogIdEscape will result in incorrect hier names
        // so we have to return unescaped names and restrict the user
        // not to use escaped identifiers
        return name; // VerilogIdEscape(name);
    }

    // obsolete
    std::vector<std::string> scope_of(Module *mod) const;

    std::string hier_name_of(Module *mod, Module *scope = nullptr) const {
        std::ostringstream ss;
        bool is_first = true;
        for (Module *m : path_of(mod, scope)) {
            if (is_first)
                is_first = false;
            else
                ss << ".";
            if (m == top_)
                ss << name_of(m->name);
            else
                ss << name_of(inst_dict.at(m)->name);
        }
        return ss.str();
    }

    template <typename T>
    std::string hier_name_of(T *obj, Module *scope = nullptr) const {
        std::ostringstream ss;
        ss << hier_name_of(obj->module, scope) << "." << name_of(obj->name);
        return ss.str();
    }

    std::string hier_name_of(SigBit bit, Module *scope = nullptr) const {
        if (bit.is_wire()) {
            std::ostringstream ss;
            ss << hier_name_of(bit.wire, scope);
            if (bit.wire->width != 1)
                ss << stringf("[%d]", bit.wire->start_offset + bit.offset);
            return ss.str();
        }
        else
            return Const(bit.data).as_string();
    }

    std::string hier_name_of(SigChunk chunk, Module *scope = nullptr) const {
        if (chunk.is_wire()) {
            std::ostringstream ss;
            ss << hier_name_of(chunk.wire, scope);
            if (chunk.size() != chunk.wire->width) {
                if (chunk.size() == 1)
                    ss << stringf("[%d]", chunk.wire->start_offset + chunk.offset);
                else if (chunk.wire->upto)
                    ss << stringf("[%d:%d]", (chunk.wire->width - (chunk.offset + chunk.width - 1) - 1) + chunk.wire->start_offset,
                            (chunk.wire->width - chunk.offset - 1) + chunk.wire->start_offset);
                else
                    ss << stringf("[%d:%d]", chunk.wire->start_offset + chunk.offset + chunk.width - 1,
                            chunk.wire->start_offset + chunk.offset);
            }
            return ss.str();
        }
        else 
            return Const(chunk.data).as_string();
    }

    bool check_hier_attr(IdString attr, Module *module) {
        return module->get_bool_attribute(attr) ||
            (instance_of(module) && check_hier_attr(attr, instance_of(module)));
    }

    template <typename T>
    bool check_hier_attr(IdString attr, T *obj) {
        return obj->get_bool_attribute(attr) ||
            check_hier_attr(attr, obj->module);
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

    DesignInfo() : design_(nullptr), top_(nullptr) {}

    DesignInfo(Design *design) {
        setup(design);
    }

};

// Hierarchical connection builder

struct HierconnBuilder {
    DesignInfo &designinfo;
    void connect(Wire *lhs, Wire *rhs, std::string suggest_name = "");
    HierconnBuilder(DesignInfo &info) : designinfo(info) {}
};

} // namespace Emu

#endif // #ifndef _DESIGNTOOLS_H_
