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
