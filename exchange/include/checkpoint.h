#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <iostream>

namespace REMU {

class Checkpoint
{
public:

    struct ImplData;

private:

    ImplData *data;

public:

    class ReadStream;
    class WriteStream;

    ReadStream readItem(std::string item);
    WriteStream writeItem(std::string item);

    uint64_t getTick();
    void setTick(uint64_t tick);

    Checkpoint(std::string path);
    ~Checkpoint();
};

class Checkpoint::ReadStream : public std::istream
{
public:

    struct ImplData;

private:

    ImplData *data;

public:

    ReadStream(ReadStream &&other) :
        std::istream(std::move(other)), data(std::move(other.data)) {}

    ReadStream(ImplData *data);

    virtual ~ReadStream();

    void close();
};

class Checkpoint::WriteStream : public std::ostream
{
public:

    struct ImplData;

private:

    ImplData *data;

public:

    WriteStream(WriteStream &&other) :
        std::ostream(std::move(other)), data(std::move(other.data)) {}

    WriteStream(ImplData *data);

    virtual ~WriteStream();

    void close();
};

};

#endif // #ifndef _CHECKPOINT_H_
