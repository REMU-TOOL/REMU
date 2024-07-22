#include "TraceBackend/Top.hpp"

#include <iostream>

using namespace std;

int main() {
  auto batch = TraceBatch({8, 34, 24, 74, 93});
  cout << batch.emitVerilog() << '\n';
  return 0;
}
