#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <set>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <boost/filesystem.hpp>
#include <boost/iostreams/filtering_streambuf.hpp>
#include <boost/iostreams/filter/gzip.hpp>

namespace Replay {

class GzipReader {
    boost::filesystem::ifstream file;
    boost::iostreams::filtering_streambuf<boost::iostreams::input> inbuf;

public:
    inline bool fail() const { return file.fail(); }
    inline std::streambuf *streambuf() { return &inbuf; }
    GzipReader(boost::filesystem::path path);
};

class Checkpoint {
    boost::filesystem::path cp_path;
    std::set<std::string> cp_filelist;

public:
    bool check_file(std::string name) const;
    boost::filesystem::path get_file_path(std::string name) const;
    uint64_t get_cycle() const;
    Checkpoint(std::string path);
};

};

#endif // #ifndef _CHECKPOINT_H_
