#ifndef _EMU_UTILS_H_
#define _EMU_UTILS_H_

#include <cstdint>
#include <vector>
#include <string>
#include <sstream>

namespace REMU {

inline uint64_t clog2(uint64_t val)
{
    uint64_t res = 0;
    val--;
    while (val > 0) {
        res++; val >>= 1;
    }
    return res;
}

inline std::vector<std::string> split_string(std::string s, char delim)
{
    std::vector<std::string> result;
    size_t start = 0, end = 0;
    while ((end = s.find(delim, start)) != std::string::npos) {
        result.push_back(s.substr(start, end));
        start = end + 1;
    }
    result.push_back(s.substr(start));
    return result;
}

inline std::string join_string(const std::vector<std::string> &vec, char delim)
{
    std::ostringstream ss;
    bool first = true;
    for (auto &s : vec) {
        if (first)
            first = false;
        else
            ss << delim;
        ss << s;
    }
    return ss.str();
}

} // namespace REMU

#endif // #ifndef _EMU_UTILS_H_
