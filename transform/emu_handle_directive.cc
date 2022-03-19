#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"
#include "interface.h"
#include "designtools.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct RewriteClockWorker {

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

    Design *design;
    DesignWalker design_walker;
    SigMapCache sigmap_cache;
    ModWalkerCache modwalker_cache;

    void replace_portbit(Cell *cell, IdString port, int offset, SigBit newbit) {
        SigSpec new_port = cell->getPort(port);
        new_port[offset] = newbit;
        cell->setPort(port, new_port);
    }

    void rewrite_clock_bits(SigBit clk, SigBit ff_clk, SigBit ram_clk) {
        // Note: we assume an identified clock port is connected to dut clock in all module instantiations

        if (!clk.is_wire())
            return;

        Module *module = clk.wire->module;
        SigMap &sigmap = sigmap_cache[module];
        sigmap.apply(clk);

        // Identify output ports

        pool<SigBit> output_bits;

        for (auto wire : module->wires())
            if (wire->port_output)
                for (SigBit b : SigSpec(wire))
                    if (sigmap(b) == clk)
                        output_bits.insert(b);

        for (auto cell : design_walker.instances_of(module)) {
            for (auto output_bit : output_bits) {
                // Add output ports

                log("Rewriting output port %s.%s[%d]\n",
                    log_id(module), log_id(output_bit.wire), output_bit.offset);

                IdString portname = output_bit.wire->name;
                IdString ff_portname = portname.str() + "_EMU_FF_CLK";
                IdString ram_portname = portname.str() + "_EMU_RAM_CLK";

                bool do_fixup_ports = false;

                Wire *ff_clk_port = module->wire(ff_portname);
                if (ff_clk_port == nullptr) {
                    ff_clk_port = module->addWire(ff_portname, output_bit.wire);
                    do_fixup_ports = true;
                }

                Wire *ram_clk_port = module->wire(ram_portname);
                if (ram_clk_port == nullptr) {
                    ram_clk_port = module->addWire(ram_portname, output_bit.wire);
                    do_fixup_ports = true;
                }

                if (do_fixup_ports)
                    module->fixup_ports();

                module->connect(SigBit(ff_clk_port, output_bit.offset), ff_clk);
                module->connect(SigBit(ram_clk_port, output_bit.offset), ram_clk);

                if (!cell->hasPort(portname))
                    continue;

                // Rewrite outer module

                if (!cell->hasPort(ff_portname))
                    cell->setPort(ff_portname, cell->module->addWire(NEW_ID, GetSize(ff_clk_port)));

                if (!cell->hasPort(ram_portname))
                    cell->setPort(ram_portname, cell->module->addWire(NEW_ID, GetSize(ram_clk_port)));

                SigBit cell_bit = cell->getPort(portname)[output_bit.offset];
                SigBit cell_ff_bit = cell->getPort(ff_portname)[output_bit.offset];
                SigBit cell_ram_bit = cell->getPort(ram_portname)[output_bit.offset];
                rewrite_clock_bits(cell_bit, cell_ff_bit, cell_ram_bit);
            }
        }

        // Identify input ports of cells

        ModWalker &modwalker = modwalker_cache[module];

        pool<ModWalker::PortBit> portbits;
        modwalker.get_consumers(portbits, SigSpec(clk));

        for (auto &portbit : portbits) {
            Cell * cell = portbit.cell;

            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                for (auto chunk : cell->getPort(ID::Q).chunks())
                    if (chunk.is_wire())
                        log("Rewriting ff cell %s.%s.%s[%d]\n",
                            log_id(module), log_id(chunk.wire), log_id(portbit.port), portbit.offset);

                replace_portbit(portbit.cell, portbit.port, portbit.offset, ff_clk);
                cell->set_bool_attribute(AttrClkRewritten);
                continue;
            }

            if (cell->is_mem_cell()) {
                log("Rewriting mem cell %s.%s.%s[%d]\n",
                    log_id(module), log_id(cell), log_id(portbit.port), portbit.offset);

                replace_portbit(portbit.cell, portbit.port, portbit.offset, ram_clk);
                cell->set_bool_attribute(AttrClkRewritten); // Note: The attribute is set if any clk port is rewritten
                continue;
            }

            Module *tpl = design->module(cell->type);

            if (tpl == nullptr)
                log_error("Cell type %s is unknown and its clock cannot be rewritten\n",
                    cell->type.c_str());

            log("Rewriting input port %s.%s[%d]\n",
                log_id(tpl), log_id(portbit.port), portbit.offset);

            IdString portname = portbit.port;
            IdString ff_portname = portname.str() + "$EMU$FF$CLK";
            IdString ram_portname = portname.str() + "$EMU$RAM$CLK";

            // Add cell ports

            SigSpec cell_port = cell->getPort(portname);

            if (!cell->hasPort(ff_portname))
                cell->setPort(ff_portname, Const(0, GetSize(cell_port)));

            if (!cell->hasPort(ram_portname))
                cell->setPort(ram_portname, Const(0, GetSize(cell_port)));

            replace_portbit(cell, ff_portname, portbit.offset, ff_clk);
            replace_portbit(cell, ram_portname, portbit.offset, ram_clk);

            // Rewrite inner module

            Wire *tpl_port = tpl->wire(portname);

            bool do_fixup_ports = false;

            Wire *tpl_ff_port = tpl->wire(ff_portname);
            if (tpl_ff_port == nullptr) {
                tpl_ff_port = tpl->addWire(ff_portname, tpl_port);
                do_fixup_ports = true;
            }

            Wire *tpl_ram_port = tpl->wire(ram_portname);
            if (tpl_ram_port == nullptr) {
                tpl_ram_port = tpl->addWire(ram_portname, tpl_port);
                do_fixup_ports = true;
            }

            if (do_fixup_ports)
                tpl->fixup_ports();

            SigBit tpl_bit = SigBit(tpl_port, portbit.offset);
            SigBit tpl_ff_bit = SigBit(tpl_ff_port, portbit.offset);
            SigBit tpl_ram_bit = SigBit(tpl_ram_port, portbit.offset);
            rewrite_clock_bits(tpl_bit, tpl_ff_bit, tpl_ram_bit);
        }
    }

    void run(Module *module, std::string clk_name, std::string ff_clk_name, std::string ram_clk_name) {
        Wire *clk = module->wire("\\" + clk_name);
        if (clk == nullptr)
            log_error("Module %s: specified port %s not found\n", log_id(module), clk_name.c_str());

        log("Module %s: rewrite clock %s to %s and %s\n",
                log_id(module), clk_name.c_str(), ff_clk_name.c_str(), ram_clk_name.c_str());

        Wire *ff_clk = module->addWire("\\" + ff_clk_name);
        Wire *ram_clk = module->addWire("\\" + ram_clk_name);

        clk->port_input = false;
        ff_clk->port_input = true;
        ram_clk->port_input = true;
        module->fixup_ports();

        rewrite_clock_bits(clk, ff_clk, ram_clk);

        module->connect(clk, State::S0);
    }

    RewriteClockWorker(Design *design) : design(design), design_walker(design) {}
};

struct ExternWorker {
    DesignHierarchy hier;

    pool<std::string> axi_suffixes = {
        "_awvalid",
        "_awready",
        "_awaddr",
        "_awprot",
        "_awid",
        "_awlen",
        "_awsize",
        "_awburst",
        "_awlock",
        "_awcache",
        "_awqos",
        "_awregion",
        "_wvalid",
        "_wready",
        "_wdata",
        "_wstrb",
        "_wlast",
        "_bvalid",
        "_bready",
        "_bresp",
        "_bid",
        "_arvalid",
        "_arready",
        "_araddr",
        "_arprot",
        "_arid",
        "_arlen",
        "_arsize",
        "_arburst",
        "_arlock",
        "_arcache",
        "_arqos",
        "_arregion",
        "_rvalid",
        "_rready",
        "_rdata",
        "_rresp",
        "_rid",
        "_rlast",
    };

    void extern_ports(const std::vector<std::string> &portnames, Module *module) {
        for (auto &name : portnames) {
            Wire *wire = module->wire("\\" + name);
            if (!wire)
                log_error("Module %s: specified port %s not found\n", log_id(module), name.c_str());

            log("Module %s: extern port %s\n", log_id(module), name.c_str());

            // TODO: to be changed
            promote_intf_port(module, name, wire);
            module->fixup_ports();
            continue;

            IdString top_wire_id = wire->module->name.str() + "." + wire->name.substr(1);
            Wire *top_wire = hier.top->addWire(top_wire_id, wire);

            if (wire->port_input)
                hier.connect(wire, top_wire);
            else
                hier.connect(top_wire, wire);
        }
        hier.top->fixup_ports();
    }

    void extern_axi_ports(const std::vector<std::string> &axinames, Module *module) {
        int count = 0;
        if (hier.top->has_attribute("\\__emu_axi_count"))
            count = hier.top->attributes.at("\\__emu_axi_count").as_int();

        for (auto &name : axinames) {
            log("Module %s: extern axi port %s\n", log_id(module), name.c_str());
            for (auto &suffix : axi_suffixes) {
                Wire *wire = module->wire("\\" + name + suffix);
                if (wire) {
                    IdString top_wire_id = stringf("\\emu_axi_%d_", count) + wire->name.substr(1);
                    Wire *top_wire = hier.top->addWire(top_wire_id, wire);

                    if (wire->port_input)
                        hier.connect(wire, top_wire);
                    else
                        hier.connect(top_wire, wire);
                }
            }
            count++;
        }
        hier.top->fixup_ports();

        hier.top->attributes["\\__emu_axi_count"] = Const(count);
    }

    ExternWorker(Design *design) : hier(design) {}
};

struct DirectiveHandler {
    static dict<std::string, DirectiveHandler *> handlers;

    static DirectiveHandler *get(std::string name) {
        try {
            return handlers.at(name);
        }
        catch (std::out_of_range const&) {
            return nullptr;
        }
    }

    static void call(std::vector<std::string> args, Module *module) {
        if (args.empty())
            return;

        DirectiveHandler *handler = get(args[0]);
        if (handler == nullptr)
            log_error("Module %s: undefined directive command %s\n", log_id(module), args[0].c_str());

        handler->execute(args, module);
    }

    DirectiveHandler(std::string name) {
        if (handlers.find(name) != handlers.end())
            log_error("DirectiveHandler: duplicate name %s\n", name.c_str());

        handlers[name] = this;
    }

    virtual void execute(std::vector<std::string> args, Module *module) = 0;
};

dict<std::string, DirectiveHandler *> DirectiveHandler::handlers;

struct RewriteClockHandler : public DirectiveHandler {
    RewriteClockHandler() : DirectiveHandler("rewrite_clk") {}
    virtual void execute(std::vector<std::string> args, Module *module) override {
        std::vector<std::string> ports;
        std::string ff_clk = "dut_ff_clk", ram_clk = "dut_ram_clk";

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-ff_clk" && argidx+1 < args.size()) {
                ff_clk = args[++argidx];
                continue;
            }
            if (args[argidx] == "-ram_clk" && argidx+1 < args.size()) {
                ram_clk = args[++argidx];
                continue;
            }
            break;
        }
        ports.assign(args.begin() + argidx, args.end());

        if (ports.size() != 1)
            log_error("Module %s: rewrite_clk: exactly 1 port required\n", log_id(module));

        RewriteClockWorker worker(module->design);
        worker.run(module, ports[0], ff_clk, ram_clk);
    }
} RewriteClockHandler;

struct ExternHandler : public DirectiveHandler {
    ExternHandler() : DirectiveHandler("extern") {}
    virtual void execute(std::vector<std::string> args, Module *module) override {
        std::vector<std::string> ports;
        bool axi = false;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            if (args[argidx] == "-axi") {
                axi = true;
                continue;
            }
            break;
        }
        ports.assign(args.begin() + argidx, args.end());

        if (ports.empty())
            log_error("Module %s: extern: port list required\n", log_id(module));

        ExternWorker worker(module->design);
        if (axi)
            worker.extern_axi_ports(ports, module);
        else
            worker.extern_ports(ports, module);
    }
} ExternHandler;

struct EmuHandleDirectiveWorker {

    Design *design;

    std::string tokenize(std::string &str) {
        std::string token;
        size_t pos = 0;
        bool in_quote = false, prev_backslash = false, leading_spaces = true;
        while (pos < str.size()) {
            char c = str[pos++];
            if (c == ' ') {
                if (leading_spaces)
                    continue;
                if (in_quote || prev_backslash) {
                    token.push_back(c);
                    prev_backslash = false;
                    continue;
                }
                break;
            }
            leading_spaces = false;
            if (c == ';') {
                if (token.empty())
                    token.push_back(c);
                else
                    pos--;
                break;
            }
            switch (c) {
            case '\\':
                if (prev_backslash) {
                    token.push_back(c);
                    prev_backslash = false;
                }
                else {
                    prev_backslash = true;
                }
                break;
            case '"':
                if (prev_backslash) {
                    token.push_back(c);
                    prev_backslash = false;
                }
                else {
                    in_quote = !in_quote;
                }
                break;
            default:
                token.push_back(c);
                break;
            }
        }
        str = str.substr(pos);
        return token;
    }

    void execute_directive(std::string directive, Module *module) {
        std::vector<std::string> args;
        std::string token;
        do {
            token = tokenize(directive);
            if (token.empty() || token == ";") {
                DirectiveHandler::call(args, module);
                args.clear();
            }
            else {
                args.push_back(token);
            }
        } while (!token.empty());
    }

    void run() {
        for (Module *module : design->modules()) {
            std::string directive = module->get_string_attribute("\\__emu_directive");
            if (!directive.empty())
                execute_directive(directive, module);
        }
    }

    EmuHandleDirectiveWorker(Design *design) : design(design) {}

};

struct EmuHandleDirectivePass : public Pass {
    EmuHandleDirectivePass() : Pass("emu_handle_directive", "handle emulation directives") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_handle_directive\n");
        log("\n");
        log("This command handles emulation directives.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_HANDLE_DIRECTIVE pass.\n");
        log_push();

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            break;
        }
        extra_args(args, argidx, design);

        EmuHandleDirectiveWorker worker(design);
        worker.run();

        log_pop();
    }
} EmuHandleDirectivePass;

PRIVATE_NAMESPACE_END
