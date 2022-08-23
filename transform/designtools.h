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
        return VerilogIdEscape(name);
    }

    template <typename T>
    std::string name_of(T* obj) const {
        return name_of(obj->name);
    }

    std::string name_of(SigBit bit) const {
        if (bit.is_wire()) {
            std::ostringstream ss;
            ss << name_of(bit.wire);
            if (bit.wire->width != 1)
                ss << stringf("[%d]", bit.wire->start_offset + bit.offset);
            return ss.str();
        }
        else
            return Const(bit.data).as_string();
    }

    std::string name_of(SigChunk chunk) const {
        if (chunk.is_wire()) {
            std::ostringstream ss;
            ss << name_of(chunk.wire);
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

    std::string hdl_name_of(Module* module) const {
        if (module->has_attribute(ID::hdlname))
            return name_of(IdString(module->get_string_attribute(ID::hdlname)));
        return name_of(module);
    }

    std::vector<std::string> hier_name_of(Module *mod, Module *scope = nullptr) const {
        std::vector<std::string> hier;
        for (Module *m : path_of(mod, scope)) {
            if (m == top_)
                hier.push_back(name_of(m->name));
            else
                hier.push_back(name_of(inst_dict.at(m)->name));
        }
        return hier;
    }

    std::vector<std::string> hier_name_of(IdString name, Module *parent, Module *scope = nullptr) const {
        std::vector<std::string> hier = hier_name_of(parent, scope);
        hier.push_back(name_of(name));
        return hier;
    }

    template <typename T>
    std::vector<std::string> hier_name_of(T *obj, Module *scope = nullptr) const {
        return hier_name_of(obj->name, obj->module, scope);
    }

    std::string flat_name_of(Module *mod, Module *scope = nullptr) const {
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

    std::string flat_name_of(IdString name, Module *parent, Module *scope = nullptr) const {
        std::string hier = flat_name_of(parent, scope);
        if (!hier.empty())
            hier += ".";
        hier += name_of(name);
        return hier;
    }

    template <typename T>
    std::string flat_name_of(T *obj, Module *scope = nullptr) const {
        return flat_name_of(obj->name, obj->module, scope);
    }

    std::string flat_name_of(SigBit bit, Module *scope = nullptr) const {
        if (bit.is_wire()) {
            std::ostringstream ss;
            ss << flat_name_of(bit.wire, scope);
            if (bit.wire->width != 1)
                ss << stringf("[%d]", bit.wire->start_offset + bit.offset);
            return ss.str();
        }
        else
            return Const(bit.data).as_string();
    }

    std::string flat_name_of(SigChunk chunk, Module *scope = nullptr) const {
        if (chunk.is_wire()) {
            std::ostringstream ss;
            ss << flat_name_of(chunk.wire, scope);
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

    bool check_hier_attr(IdString attr, Module *module) const {
        return module->get_bool_attribute(attr) ||
            (instance_of(module) && check_hier_attr(attr, instance_of(module)));
    }

    template <typename T>
    bool check_hier_attr(IdString attr, T *obj) const {
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
    pool<SigBit> find_dependencies(const pool<SigBit> &target, const pool<SigBit> *candidate = nullptr);

    DesignInfo() : design_(nullptr), top_(nullptr) {}

    DesignInfo(Design *design) {
        setup(design);
    }

};

// Hierarchical connection builder

struct HierconnBuilder {
    DesignInfo &designinfo;
    void connect(Wire *lhs, Wire *rhs, std::string suggest_name = "");
    void connect(const SigSpec &lhs, const SigSpec &rhs, std::string suggest_name = "");
    HierconnBuilder(DesignInfo &info) : designinfo(info) {}
};

} // namespace Emu

#endif // #ifndef _DESIGNTOOLS_H_
