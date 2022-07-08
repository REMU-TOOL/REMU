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

void RewriterWire::put(Wire *wire) {
    Wire *promoted_wire = rewriter.promote(wire);

    switch (put_policy) {
        case PUT_ONCE:
            log_assert(!driven);
            wrapper->connect(handles.at(wrapper), promoted_wire);
            driven = true;
            break;

        case PUT_ANDREDUCE:
        case PUT_ORREDUCE:
            log_assert(wire->width == 1);
            reduce_cell->setPort(ID::A, {
                reduce_cell->getPort(ID::A),
                promoted_wire
            });
            break;

        default:
            log_error("RewriterWire: put() called on incompatible wire %s\n", name_.c_str());
            break;
    }
}

RewriterWire::RewriterWire(EmulationRewriter &rewriter, std::string name, int width, PutPolicy put_policy, Module *wrapper)
    : rewriter(rewriter), name_(name), width_(width), put_policy(put_policy), wrapper(wrapper), reduce_cell(nullptr), driven(false)
{

    Wire *wire = wrapper->addWire(wrapper->uniquify("\\" + name), width);
    wire->set_bool_attribute(ID::keep);

    if (put_policy == PUT_ANDREDUCE) {
        log_assert(width == 1);
        reduce_cell = wrapper->addReduceAnd(NEW_ID, State::S1, wire);
    }
    else if (put_policy == PUT_ORREDUCE) {
        log_assert(width == 1);
        reduce_cell = wrapper->addReduceOr(NEW_ID, State::S0, wire);
    }

    handles[wrapper] = wire;
}

RewriterClock::RewriterClock(EmulationRewriter &rewriter, std::string name, Module *wrapper)
    : RewriterWire(rewriter, name, 1, PUT_NONE, wrapper)
{
    gate_cell = wrapper->addCell(wrapper->uniquify("\\" + name + "_gate"), "\\ClockGate");
    gate_cell->setPort("\\CLK", rewriter.wire("host_clk")->get(wrapper));
    gate_cell->setPort("\\EN", State::S1);
    gate_cell->setPort("\\OCLK", get(wrapper));
}

Wire *EmulationRewriter::promote(Wire *wire) {
    while (wire->module != wrapper_) {
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
    define_wire("run_mode");
    define_wire("scan_mode");

    define_clock("mdl_clk");
    define_clock("mdl_clk_ff");
    define_clock("mdl_clk_ram");

    define_wire("mdl_rst");
    wrapper_->connect(
        wire("mdl_rst")->get(wrapper_),
        wire("host_rst")->get(wrapper_));

    define_wire("ff_se");               // FF scan enable
    define_wire("ff_di", ff_width);     // FF scan data in
    define_wire("ff_do", ff_width);     // FF scan data out
    define_wire("ram_sr");              // RAM scan reset
    define_wire("ram_se");              // RAM scan enable
    define_wire("ram_sd");              // RAM scan direction (0=out 1=in)
    define_wire("ram_di", ram_width);   // RAM scan data in
    define_wire("ram_do", ram_width);   // RAM scan data out

    define_wire("up_req");
    define_wire("down_req");
    define_wire("up_ack", 1, PUT_ANDREDUCE);
    define_wire("down_ack", 1, PUT_ANDREDUCE);
}

EmulationRewriter::EmulationRewriter(Design *design) {
    target_ = design->top_module();
    target_->attributes.erase(ID::top);
    wrapper_ = design->addModule("\\EMU_SYSTEM");
    wrapper_->set_bool_attribute(ID::top);
    wrapper_->addCell("\\target", target_->name);

    define_wire("host_clk");
    define_wire("host_rst");
    wire("host_clk")->make_external(false);
    wire("host_rst")->make_external(false);

    designinfo.setup(design);
}
