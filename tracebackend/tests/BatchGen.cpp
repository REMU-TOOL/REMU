#include "TraceBackend/Top.hpp"
#include "TraceBackend/utils.hpp"

#include <filesystem>

using namespace std;

int main(int argc, char *argv[]) {
  auto batch = TraceBatch({8, 34, 24, 74, 93});
  utils::writeFile(filesystem::path(argv[1]), batch.emitVerilog());
  utils::writeFile(filesystem::path(argv[2]), batch.emitCHeader());
  return 0;
}
