#include "emuutil.h"

USING_YOSYS_NAMESPACE

using namespace EmuUtil;

#define WA_NAME(x) (IDGen.gen("\\$WidthAdapter." #x "_"))

void WidthAdapterBuilder::run() {
    log_assert(in_w > 0);
    log_assert(out_w > 0);

    // interfaces
    idata = module->addWire(WA_NAME(idata), in_w);
    ivalid = module->addWire(WA_NAME(ivalid));
    iready = module->addWire(WA_NAME(iready));
    odata = module->addWire(WA_NAME(odata), out_w);
    ovalid = module->addWire(WA_NAME(ovalid));
    oready = module->addWire(WA_NAME(oready));
    flush = module->addWire(WA_NAME(flush));

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
    SigSpec iptr_next = module->addWire(WA_NAME(iptr_next), cntlen);
    SigSpec optr_next = module->addWire(WA_NAME(optr_next), cntlen);
    SigSpec iptr = module->addWire(WA_NAME(iptr), cntlen);
    SigSpec optr = module->addWire(WA_NAME(optr), cntlen);
    module->addSdff(NEW_ID, clk, rst, iptr_next, iptr, Const(in_w, cntlen));
    module->addSdff(NEW_ID, clk, rst, optr_next, optr, Const(0, cntlen));

    // buffer
    SigSpec buffer_next = module->addWire(NEW_ID, buflen);
    SigSpec buffer = module->addWire(WA_NAME(buffer), buflen);
    module->addDff(NEW_ID, clk, buffer_next, buffer);

    // assign iready = iptr == IW;
    // assign ovalid = optr == OW;
    // assign odata = buffer[BUFLEN-1:IW];
    module->connect(iready, module->Eq(NEW_ID, iptr, Const(in_w, cntlen)));
    module->connect(ovalid, module->Eq(NEW_ID, optr, Const(out_w, cntlen)));
    module->connect(odata, buffer.extract(in_w, out_w));

    // indication for handshake
    // wire ifire = ivalid && iready;
    // wire ofire = ovalid && oready;
    SigSpec ifire = module->And(NEW_ID, ivalid, iready);
    SigSpec ofire = module->And(NEW_ID, ovalid, oready);

    // shift operand
    // wire [BUFLEN-1:0] shift_in = ifire ? {odata, idata} : buffer;
    SigSpec shift_in = module->Mux(WA_NAME(shift_in), buffer, {odata, idata}, ifire);

    // available shift amoount for iptr and optr respectively
    // wire [CNTLEN-1:0] iavail = (ifire || flush) ? IW : IW - iptr;
    // wire [CNTLEN-1:0] oavail = ofire ? OW : OW - optr;
    SigSpec iavail = module->Mux(WA_NAME(iavail),
        module->Sub(NEW_ID, Const(in_w, cntlen), iptr),
        Const(in_w, cntlen),
        module->Or(NEW_ID, ifire, flush)
    );
    SigSpec oavail = module->Mux(WA_NAME(oavail),
        module->Sub(NEW_ID, Const(out_w, cntlen), optr),
        Const(out_w, cntlen),
        ofire
    );

    // the final shift amount
    // wire [CNTLEN-1:0] sa = iavail < oavail ? iavail : oavail;
    SigSpec sa = module->Mux(WA_NAME(sa), oavail, iavail, module->Le(NEW_ID, iavail, oavail));

    // always @(posedge clk) begin
    //     if (rst) iptr <= IW;
    //     else iptr <= (ifire || flush) ? sa : iptr + sa;
    // end
    module->connect(iptr_next, module->Mux(NEW_ID,
        module->Add(NEW_ID, iptr, sa),
        sa,
        module->Or(NEW_ID, ifire, flush)
    ));

    // always @(posedge clk) begin
    //     if (rst) optr <= 0;
    //     else optr <= ofire ? sa : optr + sa;
    // end
    module->connect(optr_next, module->Mux(NEW_ID,
        module->Add(NEW_ID, optr, sa),
        sa,
        ofire
    ));

    // always @(posedge clk) buffer <= shift_in << sa;
    module->connect(buffer_next, module->Shl(NEW_ID, shift_in, sa));
}
