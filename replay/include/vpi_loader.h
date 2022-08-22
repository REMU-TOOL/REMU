#ifndef _VPI_LOADER_H_
#define _VPI_LOADER_H_

#include "loader.h"

namespace Replay {

class VPILoader : public BaseLoader {
    virtual void set_ff_value(std::string name, uint64_t data, int width, int offset) override;
    virtual void set_mem_value(std::string name, int index, uint64_t data, int width, int offset) override;

public:
    VPILoader(std::string sc_file, Checkpoint &checkpoint) : BaseLoader(sc_file, checkpoint) {}
};

};

#endif // #ifndef _VPI_LOADER_H_
