#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "fame.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

inline Cell* ClockGate(Module *module, IdString name, SigSpec clk, SigSpec en, SigSpec oclk)
{
    Cell *cell = module->addCell(name, "\\ClockGate");
    cell->setPort("\\CLK", clk);
    cell->setPort("\\EN", en);
    cell->setPort("\\OCLK", oclk);
    return cell;
}

// TODO: maybe channel-related code in port.cc should be moved here?

void FAMETransform::run()
{
    Module *top = design->top_module();

    SigSpec finishing = State::S1;

    // TODO: handle combinationally connected channels
    // TODO: support multiple clocks

    Wire *tick = top->addWire("\\EMU_TICK");
    tick->port_output = true;

    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *mdl_clk       = CommonPort::get(top, CommonPort::PORT_MDL_CLK);
    Wire *mdl_clk_ff    = CommonPort::get(top, CommonPort::PORT_MDL_CLK_FF);
    Wire *mdl_clk_ram   = CommonPort::get(top, CommonPort::PORT_MDL_CLK_RAM);
    Wire *mdl_rst       = CommonPort::get(top, CommonPort::PORT_MDL_RST);
    Wire *run_mode      = CommonPort::get(top, CommonPort::PORT_RUN_MODE);
    Wire *scan_mode     = CommonPort::get(top, CommonPort::PORT_SCAN_MODE);
    Wire *ff_se         = CommonPort::get(top, CommonPort::PORT_FF_SE);
    Wire *ram_se        = CommonPort::get(top, CommonPort::PORT_RAM_SE);

    SigSpec not_scan_mode = top->Not(NEW_ID, scan_mode);
    SigSpec run_and_tick = top->And(NEW_ID, run_mode, tick);

    make_internal(mdl_clk);
    make_internal(mdl_clk_ff);
    make_internal(mdl_clk_ram);

    ClockGate(top, NEW_ID, host_clk, not_scan_mode, mdl_clk);
    ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, not_scan_mode, ff_se), mdl_clk_ff);
    ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, not_scan_mode, ram_se), mdl_clk_ram);

    for (auto &info : database.user_clocks) {
        Wire *clk = top->wire("\\" + info.port_name);
        Wire *clk_ff = top->wire(info.ff_clk);
        Wire *clk_ram = top->wire(info.ram_clk);

        make_internal(clk);
        make_internal(clk_ff);
        make_internal(clk_ram);

        top->connect(clk, State::S0);
        ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, run_and_tick, ff_se), clk_ff);
        ClockGate(top, NEW_ID, host_clk, top->Or(NEW_ID, run_and_tick, ram_se), clk_ram);
    }

    for (auto &info : database.channels) {
        log("Emitting channel %s.%s\n", join_string(info.path, '.').c_str(), info.orig_name.c_str());

        Wire *valid = top->wire(info.port_valid);
        Wire *ready = top->wire(info.port_ready);
        Wire *payload_inner = top->wire(info.port_payload_inner);
        Wire *payload_outer = top->wire(info.port_payload_outer);

        make_internal(valid);
        make_internal(ready);
        make_internal(payload_inner);
        make_internal(payload_outer);

        SigSpec fire = top->And(NEW_ID, valid, ready);
        SigSpec done = top->addWire(NEW_ID);

        // always @(posedge clk)
        //   if (rst || tick)
        //     done <= 1'b0;
        //   else if (fire)
        //     done <= 1'b1;
        top->addSdffe(NEW_ID,
            mdl_clk,
            fire,
            top->Or(NEW_ID, mdl_rst, tick),
            State::S1,
            done,
            State::S0
        );

        // Note: direction is in model module's view
        if (info.dir == ChannelInfo::IN) {
            // assign valid = !done && run_mode;
            top->connect(valid, top->And(NEW_ID, top->Not(NEW_ID, done), run_mode));
            // connect payload signals
            top->connect(payload_inner, payload_outer);
        }
        else {
            // assign ready = !done && run_mode;
            top->connect(ready, top->And(NEW_ID, top->Not(NEW_ID, done), run_mode));
            // insert skid buffers for payload signals
            // always @(posedge clk)
            //   if (fire)
            //     payload_r <= payload_inner;
            // assign payload_outer = done ? payload_r : payload_inner;
            Wire *payload_r = top->addWire(NEW_ID, GetSize(payload_outer));
            top->addDffe(NEW_ID,
                mdl_clk,
                fire,
                payload_inner,
                payload_r);
            top->addMux(NEW_ID, payload_inner, payload_r, done, payload_outer);
        }

        Wire *channel_finishing = top->addWire(NEW_ID);
        top->connect(channel_finishing, top->Or(NEW_ID, fire, done));

        finishing.append(channel_finishing);
    }

    top->connect(tick, top->ReduceAnd(NEW_ID, finishing));

    top->fixup_ports();
}
