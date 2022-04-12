#include "checkpoint.h"

namespace fs = boost::filesystem;
using namespace Replay;

Checkpoint::Checkpoint(std::string path) : cp_path(path) {
    if (!fs::is_directory(cp_path))
        return;

    for (auto &x : fs::directory_iterator(cp_path)) {
        auto &cp_entry = x.path();
        if (fs::is_regular_file(cp_entry)) {
            auto cp_file = cp_entry.filename();
            if (cp_file.extension() == ".gz")
                cp_filelist.insert(cp_file.string());
        }
    }
}

bool Checkpoint::check_file(std::string name) const {
    return cp_filelist.find(name) != cp_filelist.end();
}

boost::filesystem::path Checkpoint::get_file_path(std::string name) const {
    auto path = cp_path;
    path /= name + ".gz";
    return path;
}

uint64_t Checkpoint::get_cycle() const {
    GzipReader reader(get_file_path("cycle"));
    uint64_t cycle = 0;
    std::istream istream(reader.streambuf());
    istream.read(reinterpret_cast<char*>(&cycle), sizeof(cycle));
    return cycle;
}

GzipReader::GzipReader(boost::filesystem::path path) {
    file.open(path, std::ios::binary);
    inbuf.push(boost::iostreams::gzip_decompressor());
    inbuf.push(file);
}
