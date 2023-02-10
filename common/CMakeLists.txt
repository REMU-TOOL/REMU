project(common)

set(CMAKE_CXX_STANDARD 17)

file(GLOB common-sources "*.cc")

add_library(common STATIC ${common-sources})
target_include_directories(common PUBLIC ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(common cereal)

# BitVectorTest

add_executable(BitVectorTest tests/bitvector_test.cc bitvector.cc)
target_include_directories(BitVectorTest PUBLIC ${PROJECT_SOURCE_DIR}/include)
add_test(NAME BitVectorTest COMMAND BitVectorTest)
