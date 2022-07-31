project(BitVector)

add_library(BitVector STATIC bitvector.cc)

add_executable(BitVectorTest
    bitvector_test.cc
)

target_link_libraries(BitVectorTest PRIVATE BitVector)

add_test(NAME BitVectorTest COMMAND BitVectorTest)
