#ifndef _REWRITER_H_
#define _REWRITER_H_

#include "kernel/yosys.h"
#include "designtools.h"
#include "database.h"

namespace Emu {

USING_YOSYS_NAMESPACE

class EmulationRewriter;

enum PortType {
    PORT_NONE,
    PORT_INPUT,
    PORT_OUTPUT,
    PORT_OUTPUT_ANDREDUCE,
    PORT_OUTPUT_ORREDUCE,
};

enum WireType {
    WIRE_COMMON,
    WIRE_CLOCK,
};

class RewriterWire {

protected:

    EmulationRewriter &rewriter;
    std::string name_;
    int width_;
    PortType port_type;
    dict<Module *, Wire *> handles;
    Module *wrapper;
    Cell *reduce_cell; // for PORT_OUTPUT_ANDREDUCE and PORT_OUTPUT_ORREDUCE
    bool driven;

    friend class EmulationRewriter;

public:

    virtual WireType type() const { return WIRE_COMMON; }

    std::string name() const { return name_; }
    int width() const { return width_; }
    Wire *get(Module *module);
    void put(Wire *wire);

    void make_internal() {
        Wire *wire = handles.at(wrapper);
        wire->port_input = false;
        wire->port_output = false;
        wrapper->fixup_ports();
        port_type = PORT_NONE;
    }

    RewriterWire(const RewriterWire &) = delete;
    RewriterWire &operator=(const RewriterWire &) = delete;

protected:

    RewriterWire(EmulationRewriter &rewriter, std::string name, int width, PortType put_policy, Module *wrapper);
    virtual ~RewriterWire() {}

};

class RewriterClock : public RewriterWire {

    Cell *gate_cell;

    friend class EmulationRewriter;

public:

    virtual WireType type() const { return WIRE_CLOCK; }

    SigBit getEnable() const {
        return gate_cell->getPort("\\EN");
    }

    void setEnable(SigBit enable) {
        log_assert(!enable.is_wire() || enable.wire->module == wrapper);
        gate_cell->setPort("\\EN", enable);
    }

protected:

    RewriterClock(EmulationRewriter &rewriter, std::string name, Module *wrapper);

};

class EmulationRewriter {

private:

    DesignInfo designinfo;
    dict<std::string, RewriterWire *> wires;
    Module *wrapper_;
    Module *target_;

    EmulationDatabase database_;

public:

    DesignInfo &design() {
        return designinfo;
    }

    void update_design() {
        Design *design = designinfo.design();
        log_header(design, "Updating design hierarchy.\n");
        designinfo.setup(design);
    }

    void define_wire(std::string name, int width = 1, PortType put_policy = PORT_NONE) {
        log_assert(wires.count(name) == 0);
        wires[name] = new RewriterWire(*this, name, width, put_policy, wrapper_);
    }

    void define_clock(std::string name) {
        log_assert(wires.count(name) == 0);
        wires[name] = new RewriterClock(*this, name, wrapper_);
    }

    RewriterWire *wire(std::string name) const {
        return wires.at(name);
    }

    RewriterClock *clock(std::string name) const {
        return dynamic_cast<RewriterClock *>(wire(name));
    }

    Wire *promote(Wire *wire);

    Module *wrapper() const { return wrapper_; }
    Module *target() const { return target_; }

    void setup_wires(int ff_width, int ram_width);

    EmulationDatabase &database() { return database_; }
    const EmulationDatabase &database() const { return database_; }

    EmulationRewriter(Design *design);

    ~EmulationRewriter() {
        for (auto &it : wires)
            delete it.second;
    }

};

} // namespace Emu

#endif // #ifndef _REWRITER_H_
