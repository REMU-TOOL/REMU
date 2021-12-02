#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

void propagate_const_from_old_sig(std::vector<SigBit> &out, const SigSpec &old_sig, const SigSpec &new_sig) {
    std::vector<SigBit> old_bits = old_sig.to_sigbit_vector();
    std::vector<SigBit> new_bits = new_sig.to_sigbit_vector();
    out.empty();
    for (int i = 0; i < GetSize(old_bits); i++) {
        if (old_bits[i].is_wire())
            out.push_back(new_bits[i]);
        else
            out.push_back(old_bits[i]);
    }
}

struct ExtractMemWorker {
    Module *module;
    ExtractMemWorker(Module* module): module(module) {}
    void run() {
        std::vector<Mem> mem_cells = Mem::get_selected_memories(module);
        for (auto mem : mem_cells) {
            mem.check();

            // generate name for new module
            const char *p_memid = mem.memid.c_str();
            std::string modprefix = "\\ExtractMem." + std::string(p_memid[0] == '\\' ? p_memid + 1 : p_memid) + "_";
            IdString modname;
            for (int i=0;; i++) {
                modname = modprefix + stringf("%d", i);
                if (!module->design->module(modname))
                    break;
            }

            // create the new module

            Module *newmod = module->design->addModule(modname);
            Cell *newmem = newmod->addCell(mem.memid, mem.cell);

            // replace mem cell with module cell

            if (!mem.packed) {
                mem.packed = true;
                mem.emit();
            }

            SigSpec rd_clk  = mem.cell->getPort(ID::RD_CLK);
            SigSpec rd_en   = mem.cell->getPort(ID::RD_EN);
            SigSpec rd_arst = mem.cell->getPort(ID::RD_ARST);
            SigSpec rd_srst = mem.cell->getPort(ID::RD_SRST);
            SigSpec rd_addr = mem.cell->getPort(ID::RD_ADDR);
            SigSpec rd_data = mem.cell->getPort(ID::RD_DATA);
            SigSpec wr_clk  = mem.cell->getPort(ID::WR_CLK);
            SigSpec wr_en   = mem.cell->getPort(ID::WR_EN);
            SigSpec wr_addr = mem.cell->getPort(ID::WR_ADDR);
            SigSpec wr_data = mem.cell->getPort(ID::WR_DATA);

            mem.remove();
            Cell *cell = module->addCell(mem.memid, modname);

            cell->setPort(ID::RD_CLK,   rd_clk);
            cell->setPort(ID::RD_EN,    rd_en);
            cell->setPort(ID::RD_ARST,  rd_arst);
            cell->setPort(ID::RD_SRST,  rd_srst);
            cell->setPort(ID::RD_ADDR,  rd_addr);
            cell->setPort(ID::RD_DATA,  rd_data);
            cell->setPort(ID::WR_CLK,   wr_clk);
            cell->setPort(ID::WR_EN,    wr_en);
            cell->setPort(ID::WR_ADDR,  wr_addr);
            cell->setPort(ID::WR_DATA,  wr_data);

            // complete the new module

            Wire *wire_rd_clk   = newmod->addWire(ID::RD_CLK,   GetSize(rd_clk));   wire_rd_clk     ->port_input = true;
            Wire *wire_rd_en    = newmod->addWire(ID::RD_EN,    GetSize(rd_en));    wire_rd_en      ->port_input = true;
            Wire *wire_rd_arst  = newmod->addWire(ID::RD_ARST,  GetSize(rd_arst));  wire_rd_arst    ->port_input = true;
            Wire *wire_rd_srst  = newmod->addWire(ID::RD_SRST,  GetSize(rd_srst));  wire_rd_srst    ->port_input = true;
            Wire *wire_rd_addr  = newmod->addWire(ID::RD_ADDR,  GetSize(rd_addr));  wire_rd_addr    ->port_input = true;
            Wire *wire_rd_data  = newmod->addWire(ID::RD_DATA,  GetSize(rd_data));  wire_rd_data    ->port_output = true;
            Wire *wire_wr_clk   = newmod->addWire(ID::WR_CLK,   GetSize(wr_clk));   wire_wr_clk     ->port_input = true;
            Wire *wire_wr_en    = newmod->addWire(ID::WR_EN,    GetSize(wr_en));    wire_wr_en      ->port_input = true;
            Wire *wire_wr_addr  = newmod->addWire(ID::WR_ADDR,  GetSize(wr_addr));  wire_wr_addr    ->port_input = true;
            Wire *wire_wr_data  = newmod->addWire(ID::WR_DATA,  GetSize(wr_data));  wire_wr_data    ->port_input = true;
            newmod->fixup_ports();

            std::vector<SigBit> new_rd_clk, new_rd_en, new_rd_arst, new_rd_srst, new_rd_addr, new_wr_clk, new_wr_en, new_wr_addr, new_wr_data;

            propagate_const_from_old_sig(new_rd_clk,    rd_clk,     wire_rd_clk);
            propagate_const_from_old_sig(new_rd_en,     rd_en,      wire_rd_en);
            propagate_const_from_old_sig(new_rd_arst,   rd_arst,    wire_rd_arst);
            propagate_const_from_old_sig(new_rd_srst,   rd_srst,    wire_rd_srst);
            propagate_const_from_old_sig(new_rd_addr,   rd_addr,    wire_rd_addr);
            propagate_const_from_old_sig(new_wr_clk,    wr_clk,     wire_wr_clk);
            propagate_const_from_old_sig(new_wr_en,     wr_en,      wire_wr_en);
            propagate_const_from_old_sig(new_wr_addr,   wr_addr,    wire_wr_addr);
            propagate_const_from_old_sig(new_wr_data,   wr_data,    wire_wr_data);

            for (int i = 0; i < GetSize(mem.rd_ports); i++) {
                auto &port = mem.rd_ports[i];
                for (int j = 0; j < GetSize(mem.wr_ports); j++) {
                    if (port.transparency_mask[j] || port.collision_x_mask[j]) {
                        new_wr_clk[j] = new_rd_clk[i];
                    }
                }
            }
            
            for (int i = 0; i < GetSize(mem.wr_ports); i++) {
                auto &port = mem.wr_ports[i];
                for (int j = 0; j < GetSize(mem.wr_ports); j++) {
                    if (port.priority_mask[j]) {
                        new_wr_clk[j] = new_wr_clk[i];
                    }
                }
            }

            std::vector<SigBit> old_wr_en = wr_en.to_sigbit_vector();
            SigBit old_prev = State::S1, new_prev = State::S1;
            for (int i = 0; i < GetSize(old_wr_en); i++) {
                if (old_wr_en[i] != old_prev) {
                    old_prev = old_wr_en[i];
                    new_prev = new_wr_en[i];
                }
                new_wr_en[i] = new_prev;
            }

            newmod->fixup_ports();
            newmem->setPort(ID::RD_CLK,     new_rd_clk);
            newmem->setPort(ID::RD_EN,      new_rd_en);
            newmem->setPort(ID::RD_ARST,    new_rd_arst);
            newmem->setPort(ID::RD_SRST,    new_rd_srst);
            newmem->setPort(ID::RD_ADDR,    wire_rd_addr);
            newmem->setPort(ID::RD_DATA,    wire_rd_data);
            newmem->setPort(ID::WR_CLK,     new_wr_clk);
            newmem->setPort(ID::WR_EN,      new_wr_en);
            newmem->setPort(ID::WR_ADDR,    wire_wr_addr);
            newmem->setPort(ID::WR_DATA,    wire_wr_data);

            module->check();
            newmod->check();
        }
    }
};

struct EmuExtractMemPass : public Pass {
    EmuExtractMemPass() : Pass("emu_extract_mem", "extract memories into separate modules") { }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_EXTRACT_MEM pass.\n");

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            break;
        }
        extra_args(args, argidx, design);

        std::vector<Module *> modlist;
        for (auto mod : design->modules()) {
            modlist.push_back(mod);
        }

        for (auto mod : modlist) {
            log("Processing module %s...\n", log_id(mod));

            ExtractMemWorker worker(mod);
            worker.run();
        }
    }
} EmuExtractMemPass;

PRIVATE_NAMESPACE_END
