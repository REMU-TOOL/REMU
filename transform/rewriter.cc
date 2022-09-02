#include "kernel/yosys.h"

#include "emu.h"
#include "rewriter.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

Wire *RewriterWire::get(Module *module) {
    if (handles.count(module) > 0)
        return handles.at(module);

    Cell *inst_cell = rewriter.design().instance_of(module);
    Module *parent_mod = inst_cell->module;
    Wire *parent_wire = get(parent_mod);

    Wire *wire = module->addWire(module->uniquify("\\" + name_), parent_wire->width);
    wire->port_input = true;
    module->fixup_ports();

    inst_cell->setPort(wire->name, parent_wire);

    handles[module] = wire;
    return wire;
}

void RewriterWire::get(Wire *wire) {
    Module *module = wire->module;

    if (handles.count(module) > 0) {
        module->connect(wire, handles.at(module));
        return;
    }

    if (wire->port_output) {
        Wire *new_wire = module->addWire(module->uniquify(wire->name), wire->width);
        module->connect(wire, new_wire);
        wire = new_wire;
    }

    wire->port_input = true;
    module->fixup_ports();

    Cell *inst_cell = rewriter.design().instance_of(module);
    inst_cell->setPort(wire->name, get(inst_cell->module));

    handles[module] = wire;
}

void RewriterWire::put(Wire *wire) {
    Wire *promoted_wire = rewriter.promote(wire);

    switch (port_type) {
        case PORT_NONE:
        case PORT_OUTPUT:
            log_assert(!driven);
            wrapper->connect(handles.at(wrapper), promoted_wire);
            driven = true;
            break;

        case PORT_OUTPUT_ANDREDUCE:
        case PORT_OUTPUT_ORREDUCE:
            log_assert(wire->width == 1);
            {
                SigSpec new_a = {
                    reduce_cell->getPort(ID::A),
                    promoted_wire
                };
                reduce_cell->setPort(ID::A, new_a);
                reduce_cell->setParam(ID::A_WIDTH, GetSize(new_a));
            }
            break;

        default:
            log_error("RewriterWire: put() called on incompatible wire %s\n", name_.c_str());
            break;
    }
}

RewriterWire::RewriterWire(EmulationRewriter &rewriter, std::string name, int width, PortType port_type, Module *wrapper)
    : rewriter(rewriter), name_(name), width_(width), port_type(port_type), wrapper(wrapper), reduce_cell(nullptr), driven(false)
{

    Wire *wire = wrapper->addWire(wrapper->uniquify("\\" + name), width);
    wire->set_bool_attribute(ID::keep);

    switch (port_type) {
        case PORT_INPUT:
            wire->port_input = true;
            wrapper->fixup_ports();
            break;
        case PORT_OUTPUT:
        case PORT_OUTPUT_ANDREDUCE:
        case PORT_OUTPUT_ORREDUCE:
            wire->port_output = true;
            wrapper->fixup_ports();
            break;
        default:
            break;
    }

    switch (port_type) {
        case PORT_OUTPUT_ANDREDUCE:
            log_assert(width == 1);
            reduce_cell = wrapper->addReduceAnd(NEW_ID, State::S1, wire);
            driven = true;
            break;
        case PORT_OUTPUT_ORREDUCE:
            log_assert(width == 1);
            reduce_cell = wrapper->addReduceOr(NEW_ID, State::S0, wire);
            driven = true;
            break;
        default:
            break;
    }

    handles[wrapper] = wire;
}

RewriterClock::RewriterClock(EmulationRewriter &rewriter, std::string name, Module *wrapper)
    : RewriterWire(rewriter, name, 1, PORT_NONE, wrapper)
{
    gate_cell = wrapper->addCell(wrapper->uniquify("\\" + name + "_gate"), "\\ClockGate");
    gate_cell->setPort("\\CLK", rewriter.wire("host_clk")->get(wrapper));
    gate_cell->setPort("\\EN", State::S1);
    gate_cell->setPort("\\OCLK", get(wrapper));
}

Wire *EmulationRewriter::promote(Wire *wire) {
    while (wire->module != wrapper_) {
        if (wire->port_input) {
            Wire *new_wire = wire->module->addWire(wire->module->uniquify(wire->name), wire->width);
            wire->module->connect(new_wire, wire);
            wire = new_wire;
        }
        wire->port_output = true;
        wire->module->fixup_ports();
        Cell *inst_cell = designinfo.instance_of(wire->module);
        Module *parent = inst_cell->module;
        Wire *parent_wire = parent->addWire(parent->uniquify(wire->name), wire->width);
        inst_cell->setPort(wire->name, parent_wire);
        wire = parent_wire;
    }
    return wire;
}

void EmulationRewriter::setup_wires(int ff_width, int ram_width) {
    define_wire("run_mode",         1,  PORT_INPUT);
    define_wire("scan_mode",        1,  PORT_INPUT);

    define_wire("ff_se",            1,          PORT_INPUT);    // FF scan enable
    define_wire("ff_di",            ff_width,   PORT_INPUT);    // FF scan data in
    define_wire("ff_do",            ff_width,   PORT_OUTPUT);   // FF scan data out
    define_wire("ram_sr",           1,          PORT_INPUT);    // RAM scan reset
    define_wire("ram_se",           1,          PORT_INPUT);    // RAM scan enable
    define_wire("ram_sd",           1,          PORT_INPUT);    // RAM scan direction (0=out 1=in)
    define_wire("ram_di",           ram_width,  PORT_INPUT);    // RAM scan data in
    define_wire("ram_do",           ram_width,  PORT_OUTPUT);   // RAM scan data out

    define_wire("idle",             1,  PORT_OUTPUT_ANDREDUCE);

    define_clock("mdl_clk");
    define_clock("mdl_clk_ff");
    define_clock("mdl_clk_ram");

    define_wire("mdl_rst");
    wire("mdl_rst")->put(wire("host_rst")->get(wrapper_));
}

EmulationRewriter::EmulationRewriter(Design *design) {
    target_ = design->top_module();
    if (target_ == nullptr)
        log_error("no top module found\n");

    target_->attributes.erase(ID::top);
    wrapper_ = design->addModule("\\EMU_SYSTEM");
    wrapper_->set_bool_attribute(ID::top);
    wrapper_->addCell("\\target", target_->name);

    define_wire("host_clk", 1,  PORT_INPUT);
    define_wire("host_rst", 1,  PORT_INPUT);

    designinfo.setup(design);
}
