#include "checkpoint.h"

#include <set>
#include <string>
#include <fstream>
#include <sstream>
#include <boost/filesystem.hpp>
#include <boost/iostreams/filtering_streambuf.hpp>
#include <boost/iostreams/filter/gzip.hpp>

namespace fs = boost::filesystem;

using namespace Emu;

struct Checkpoint::ReadStream::ImplData
{
    boost::filesystem::ifstream file;
    boost::iostreams::filtering_streambuf<boost::iostreams::input> inbuf;

    ImplData(boost::filesystem::path path)
    {
        file.open(path, std::ios::in | std::ios::binary);
        inbuf.push(boost::iostreams::gzip_decompressor());
        inbuf.push(file);
    }

    void close()
    {
        boost::iostreams::close(inbuf);
        file.close();
    }
};

// the data pointer must be created by new
Checkpoint::ReadStream::ReadStream(Checkpoint::ReadStream::ImplData *data) : std::istream(&data->inbuf) {}
Checkpoint::ReadStream::~ReadStream() { close(); delete data; }
void Checkpoint::ReadStream::close() { data->close(); }

struct Checkpoint::WriteStream::ImplData
{
    boost::filesystem::ofstream file;
    boost::iostreams::filtering_streambuf<boost::iostreams::output> outbuf;

    ImplData(boost::filesystem::path path)
    {
        file.open(path, std::ios::out | std::ios::binary);
        outbuf.push(boost::iostreams::gzip_compressor());
        outbuf.push(file);
    }

    void close()
    {
        boost::iostreams::close(outbuf);
        file.close();
    }
};

Checkpoint::WriteStream::WriteStream(Checkpoint::WriteStream::ImplData *data) : std::ostream(&data->outbuf) {}
Checkpoint::WriteStream::~WriteStream() { close(); delete data; }
void Checkpoint::WriteStream::close() { data->close(); }

struct Checkpoint::ImplData
{
    boost::filesystem::path path;
    boost::filesystem::path getItemPath(std::string item) const
    {
        return path / (item + ".gz");
    }
};

Checkpoint::Checkpoint(std::string path)
{
    data = new ImplData;
    data->path = path;
}

Checkpoint::~Checkpoint()
{
    delete data;
}

Checkpoint::ReadStream Checkpoint::readItem(std::string item)
{
    return new ReadStream::ImplData(data->getItemPath(item));
}

Checkpoint::WriteStream Checkpoint::writeItem(std::string item)
{
    return new WriteStream::ImplData(data->getItemPath(item));
}

uint64_t Checkpoint::getTick()
{
    auto istream = readItem("tick");
    uint64_t tick = 0;
    istream.read(reinterpret_cast<char*>(&tick), sizeof(tick));
    return tick;
}

void Checkpoint::setTick(uint64_t tick)
{
    auto ostream = writeItem("tick");
    ostream.write(reinterpret_cast<char*>(&tick), sizeof(tick));
}
