#ifndef _EMUUTIL_H_
#define _EMUUTIL_H_

#include "kernel/yosys.h"

namespace EmuUtil {

    class LogicBuilder {
    protected:
        Yosys::Module *module;

    public:
        LogicBuilder(Yosys::Module *mod) : module(mod) {}

        virtual void run() {}
    };

    class WidthAdapterBuilder : public LogicBuilder {
    public:
        WidthAdapterBuilder(Yosys::Module *mod, int in_width, int out_width, Yosys::SigSpec clock, Yosys::SigSpec reset)
            : LogicBuilder(mod), in_w(in_width), out_w(out_width), clk(clock), rst(reset) {}

        virtual void run();

        Yosys::SigSpec s_idata() const { return idata; }
        Yosys::SigSpec s_ivalid() const { return ivalid; }
        Yosys::SigSpec s_iready() const { return iready; }
        Yosys::SigSpec s_odata() const { return odata; }
        Yosys::SigSpec s_ovalid() const { return ovalid; }
        Yosys::SigSpec s_oready() const { return oready; }
        Yosys::SigSpec s_flush() const { return flush; }

    private:
        int in_w, out_w;
        Yosys::SigSpec clk, rst;
        Yosys::SigSpec idata, ivalid, iready, odata, ovalid, oready, flush;
    };

    std::string get_sig_src(Yosys::SigSpec sig);

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
