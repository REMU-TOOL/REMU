#ifndef _EMUUTIL_H_
#define _EMUUTIL_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace EmuUtil {

    std::string verilog_id(const std::string &name);
    std::string verilog_hier_name(const std::vector<std::string> &hier);

    struct FfInfoChunk {
        std::vector<std::string> name;
        int offset;
        int width;
        FfInfoChunk(std::vector<std::string> &n, int o, int w) : name(n), offset(o), width(w) {}
        FfInfoChunk extract(int offset, int length) {
            return FfInfoChunk(name, this->offset + offset, length);
        }
    };

    struct FfInfo {
        std::vector<FfInfoChunk> info;
        FfInfo() {}
        FfInfo(Yosys::SigSpec);
        FfInfo(std::string);
        operator std::string();
        FfInfo extract(int offset, int length);
    };

    struct MemInfo {
        std::vector<std::string> name;
        int depth;
        int mem_width;
        int mem_depth;
        int mem_start_offset;
        MemInfo() {}
        MemInfo(Yosys::Mem &mem, int depth);
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
