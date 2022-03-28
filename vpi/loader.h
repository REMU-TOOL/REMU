#ifndef _LOADER_H_
#define _LOADER_H_

#include <string>
#include <vector>
#include <fstream>

#include "yaml-cpp/yaml.h"

namespace Reconstruct {

struct load_cb_data {
    std::string config_file;
    std::string data_file;
};

class Loader {

    bool finished = false;

public:

    bool isFinished() const { return finished; }

    Loader(std::string yaml_file, std::string checkpoint_file);
    Loader(std::vector<std::string> args);

};

};

#endif // #ifndef _LOADER_H_
