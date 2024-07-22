#include "TraceBackend/Top.hpp"

#include <iostream>

using namespace std;

int main() {
  auto batch = TraceBatch({6, 34, 26, 74, 93});
  cout << batch.emitVerilog() << endl;
  return 0;
}
