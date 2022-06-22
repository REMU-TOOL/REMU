#ifndef _LOADER_H_
#define _LOADER_H_

#include "checkpoint.h"
#include "yaml-cpp/yaml.h"

namespace Replay {

class BaseLoader {
    std::string m_sc_file;
    Checkpoint &m_checkpoint;

    virtual void set_ff_value(std::string name, uint64_t data, int width, int offset) = 0;
    virtual void set_mem_value(std::string name, int index, uint64_t data, int width, int offset) = 0;

    void load_ff(std::istream &data_stream, YAML::Node &config);
    void load_mem(std::istream &data_stream, YAML::Node &config);

public:
    bool load();
    BaseLoader(std::string sc_file, Checkpoint &checkpoint)
        : m_sc_file(sc_file), m_checkpoint(checkpoint) {}
};

class PrintLoader : public BaseLoader {
    virtual void set_ff_value(std::string name, uint64_t data, int width, int offset) override;
    virtual void set_mem_value(std::string name, int index, uint64_t data, int width, int offset) override;

public:
    PrintLoader(std::string sc_file, Checkpoint &checkpoint) : BaseLoader(sc_file, checkpoint) {}
};

};

#endif // #ifndef _LOADER_H_
