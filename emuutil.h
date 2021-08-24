#ifndef _EMUUTIL_H_
#define _EMUUTIL_H_

#include "kernel/yosys.h"

namespace EmuUtil {

    USING_YOSYS_NAMESPACE

    class LogicBuilder {
    protected:
        Module *module;

    public:
        LogicBuilder(Module *mod) : module(mod) {}

        virtual void run() {}
    };

    class WidthAdapterBuilder : public LogicBuilder {
    public:
        WidthAdapterBuilder(Module *mod, int in_width, int out_width, SigSpec clock, SigSpec reset)
            : LogicBuilder(mod), in_w(in_width), out_w(out_width), clk(clock), rst(reset) {}

        virtual void run();

        SigSpec s_idata() const { return idata; }
        SigSpec s_ivalid() const { return ivalid; }
        SigSpec s_iready() const { return iready; }
        SigSpec s_odata() const { return odata; }
        SigSpec s_ovalid() const { return ovalid; }
        SigSpec s_oready() const { return oready; }
        SigSpec s_flush() const { return flush; }

    private:
        int in_w, out_w;
        SigSpec clk, rst;
        SigSpec idata, ivalid, iready, odata, ovalid, oready, flush;
    };

    struct {
        size_t count = 0;
        std::string operator()(std::string prefix) {
            std::stringstream s;
            s << prefix << count++;
            return s.str();
        }
    } IDGen;

}

#endif // #ifndef _EMUUTIL_H_
