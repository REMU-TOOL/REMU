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

    struct SrcInfoChunk {
        std::string name;
        int offset;
        int width;
        SrcInfoChunk(std::string n, int o, int w) : name(n), offset(o), width(w) {}
        SrcInfoChunk(Yosys::SigChunk c)
            : name(c.is_wire() ? c.wire->name.str() : ""), offset(c.offset), width(c.width) {}
        SrcInfoChunk extract(int offset, int length) {
            return SrcInfoChunk(name, this->offset + offset, length);
        }
    };

    struct SrcInfo {
        std::vector<SrcInfoChunk> info;
        SrcInfo() {}
        SrcInfo(Yosys::SigSpec);
        SrcInfo(std::string);
        operator std::string();
        SrcInfo extract(int offset, int length);
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
