#include "TraceBackend/Top.hpp"
#include "TraceBackend/utils.hpp"
#include <filesystem>

using namespace std;

int main(int argc, char *argv[]) {
  auto backend = TraceBackend({6, 34, 26, 78, 64, 90});
  utils::writeFile(filesystem::path(argv[1]), backend.emitVerilog());
  utils::writeFile(filesystem::path(argv[2]), backend.emitCHeader());
  return 0;
}
