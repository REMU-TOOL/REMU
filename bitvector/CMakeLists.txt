project(bitvector)

add_library(bitvector STATIC bitvector.cc)
target_include_directories(bitvector PUBLIC .)

# BitVectorTest

add_executable(BitVectorTest bitvector_test.cc)
target_link_libraries(BitVectorTest bitvector)
add_test(NAME BitVectorTest COMMAND BitVectorTest)
