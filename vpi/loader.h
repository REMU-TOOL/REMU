#ifndef _LOADER_H_
#define _LOADER_H_

#include <string>
#include <vector>
#include <fstream>

#include "yaml-cpp/yaml.h"

namespace Reconstruct {

void sc_load(std::string config_file, std::string data_file);

};

#endif // #ifndef _LOADER_H_
