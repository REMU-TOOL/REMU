#include "emuutil.h"

USING_YOSYS_NAMESPACE

namespace EmuUtil {

    SrcInfo::SrcInfo(SigSpec sig) {
        for (auto &c : sig.chunks()) {
            info.push_back(c);
        }
    }

    SrcInfo::SrcInfo(std::string str) {
        std::istringstream s(str);
        std::string name;
        int offset, width;
        while (s >> name && s >> offset && s >> width)
            info.push_back(SrcInfoChunk(name, offset, width));
    }

    SrcInfo::operator std::string() {
        std::ostringstream s;
        bool first = true;
        for (auto &c : info) {
            if (c.name.empty())
                continue;
            if (first)
                first = false;
            else
                s << " ";
            s << c.name << " " << c.offset << " " << c.width;
        }
        return s.str();
    }

    SrcInfo SrcInfo::extract(int offset, int length) {
        SrcInfo res;
        auto it = info.begin();
        int chunkoff = 0, chunklen = 0;
        while (offset > 0) {
            if (it->width > offset) {
                chunkoff = offset;
                offset = 0;
            }
            else {
                offset -= it->width;
                ++it;
            }
        }
        while (length > 0) {
            if (it->width > length) {
                chunklen = length;
                length = 0;
            }
            else {
                chunklen = it->width;
                length -= chunklen;
            }
            res.info.push_back(it->extract(chunkoff, chunklen));
            chunkoff = 0;
            ++it;
        }
        return res;
    }

    JsonWriter &JsonWriter::key(const std::string &key) {
        comma_and_newline();
        indent();
        os << "\"" << key << "\": ";
        after_key = true;
        return *this;
    }

    JsonWriter &JsonWriter::string(const std::string &str) {
        value_preoutput();
        os << "\"";
        for (char c : str) {
            switch (c) {
                case '"':   os << "\\\"";   break;
                case '\\':  os << "\\\\";   break;
                default:    os << c;        break;
            }
        }
        os << "\"";
        after_key = false;
        return *this;
    }

    JsonWriter &JsonWriter::enter_array() {
        value_preoutput();
        os << "[\n";
        stack.push_back({']', false});
        after_key = false;
        return *this;
    }

    JsonWriter &JsonWriter::enter_object() {
        value_preoutput();
        os << "{\n";
        stack.push_back({'}', false});
        after_key = false;
        return *this;
    }

    JsonWriter &JsonWriter::back() {
        char c = stack.back().first;
        stack.pop_back();
        os << "\n";
        indent();
        os << c;
        after_key = false;
        return *this;
    }

    void JsonWriter::end() {
        while (stack.size() > 0)
            back();
    }

    JsonWriter::JsonWriter(std::ostream &os): os(os), after_key(false) {
        os << "{\n";
        stack.push_back({'}', false});
    }

    JsonWriter::~JsonWriter() {
        end();
    }

};
