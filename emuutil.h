#ifndef _EMUUTIL_H_
#define _EMUUTIL_H_

#include "kernel/yosys.h"

namespace EmuUtil {

    class LogicBuilder {
    protected:
        Module *module;

    public:
        LogicBuilder(Module *mod) : module(mod) {}

        virtual void run() {}
    };

    class WidthAdapterBuilder : public LogicBuilder {
        WidthAdapterBuilder(Module *mod, int in_width, int out_width, SigSpec clock, SigSpec reset)
            : LogicBuilder(mod), in_w(in_width), out_w(out_width), clk(clock), rst(reset) {}

        virtual void run();

        SigSpec in_data() const { return idata; }
        SigSpec in_valid() const { return ivalid; }
        SigSpec in_ready() const { return iready; }
        SigSpec out_data() const { return odata; }
        SigSpec out_valid() const { return ovalid; }
        SigSpec out_ready() const { return oready; }

    private:
        int in_w, out_w;
        SigSpec clk, rst;
        SigSpec idata, ivalid, iready, odata, ovalid, oready;
    };

}

#endif // #ifndef _EMUUTIL_H_
