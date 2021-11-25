#ifndef _EMUUTIL_H_
#define _EMUUTIL_H_

#include "kernel/yosys.h"

namespace EmuUtil {

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

    class JsonWriter {
        std::ostream &os;
        std::vector<std::pair<char, bool>> stack;
        bool after_key;

        inline void indent() {
            os << std::string(stack.size() * 4, ' ');
        }

        inline void comma_and_newline() {
            if (!stack.back().second) {
                stack.back().second = true;
            }
            else {
                os << ",\n";
            }
        }

        inline void value_preoutput() {
            if (!after_key) {
                comma_and_newline();
                indent();
            }
        }

    public:

        JsonWriter &key(const std::string &key);
        JsonWriter &string(const std::string &str);

        template <typename T> inline JsonWriter &value(const T &value) {
            value_preoutput();
            os << value;
            after_key = false;
            return *this;
        }

        JsonWriter &enter_array();
        JsonWriter &enter_object();
        JsonWriter &back();
        void end();

        JsonWriter(std::ostream &os);
        ~JsonWriter();
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
