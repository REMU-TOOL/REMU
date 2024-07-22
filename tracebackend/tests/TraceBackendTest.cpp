#include "TraceBackend/Top.hpp"

#include <iostream>

using namespace std;

int main() {
  auto backend = TraceBackend({6, 34, 26});
  cout << backend.emitVerilog() << endl;
  return 0;
}
