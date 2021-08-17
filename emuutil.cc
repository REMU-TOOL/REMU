#include "emuutil.h"

USING_YOSYS_NAMESPACE

using namespace EmuUtil;

void WidthAdapterBuilder::run() {
    log_assert(in_w > 0);
    log_assert(out_w > 0);

    // interfaces
    SigSpec idata = module->addWire(NEW_ID, in_w);
    SigSpec ivalid = module->addWire(NEW_ID);
    SigSpec iready = module->addWire(NEW_ID);
    SigSpec odata = module->addWire(NEW_ID, out_w);
    SigSpec ovalid = module->addWire(NEW_ID);
    SigSpec oready = module->addWire(NEW_ID);

    // trivial case
    if (in_w == out_w) {
        module->connect(iready, oready);
        module->connect(ovalid, ivalid);
        module->connect(odata, idata);
        return;
    }

    // constants
    const int buflen = in_w + out_w;
    const int max_w = in_w > out_w ? in_w : out_w;
    const int cntlen = ceil_log2(max_w + 1);

    // iptr & optr registers
    SigSpec iptr_next = module->addWire(NEW_ID, cntlen);
    SigSpec optr_next = module->addWire(NEW_ID, cntlen);
    SigSpec iptr, optr;
    module->addSdff(NEW_ID, clk, rst, iptr_next, iptr, in_w);
    module->addSdff(NEW_ID, clk, rst, optr_next, optr, 0);

    // buffer
    SigSpec buffer_next = module->addWire(NEW_ID, buflen);
    SigSpec buffer;
    module->addDff(NEW_ID, clk, buffer_next, buffer);

    // assign iready = iptr == IW;
    // assign ovalid = optr == OW;
    // assign odata = buffer[BUFLEN-1:IW];
    module->connect(iready, module->Eq(NEW_ID, iptr, in_w));
    module->connect(ovalid, module->Eq(NEW_ID, optr, out_w));
    module->connect(odata, buffer.extract(in_w, out_w));

    // indication for handshake
    // wire ifire = ivalid && iready;
    // wire ofire = ovalid && oready;
    SigSpec ifire = module->And(NEW_ID, ivalid, iready);
    SigSpec ofire = module->And(NEW_ID, ovalid, oready);

    // shift operand
    // wire [BUFLEN-1:0] shift_in = ifire ? {odata, idata} : buffer;
    SigSpec shift_in = module->Mux(NEW_ID, buffer, {odata, idata}, ifire);

    // available shift amoount for iptr and optr respectively
    // wire [CNTLEN-1:0] iavail = ifire ? IW : IW - iptr;
    // wire [CNTLEN-1:0] oavail = ofire ? OW : OW - optr;
    SigSpec iavail = module->Mux(NEW_ID, module->Sub(NEW_ID, in_w, iptr), in_w, ifire);
    SigSpec oavail = module->Mux(NEW_ID, module->Sub(NEW_ID, out_w, optr), out_w, ofire);

    // the final shift amount
    // wire [CNTLEN-1:0] sa = iavail < oavail ? iavail : oavail;
    SigSpec sa = module->Mux(NEW_ID, oavail, iavail, module->Le(NEW_ID, iavail, oavail));

    // always @(posedge clk) begin
    //     if (rst) iptr <= IW;
    //     else iptr <= ifire ? sa : iptr + sa;
    // end
    module->connect(iptr_next, module->Mux(NEW_ID, module->Add(NEW_ID, iptr, sa), sa, ifire));

    // always @(posedge clk) begin
    //     if (rst) optr <= 0;
    //     else optr <= ofire ? sa : optr + sa;
    // end
    module->connect(optr_next, module->Mux(NEW_ID, module->Add(NEW_ID, optr, sa), sa, ofire));

    // always @(posedge clk) buffer <= shift_in << sa;
    module->connect(buffer_next, module->Shl(NEW_ID, shift_in, sa));
}
