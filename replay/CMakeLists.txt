find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(replay)

include_directories(${PROJECT_SOURCE_DIR}/include)
include_directories(${Boost_INCLUDE_DIRS})

link_libraries(yaml-cpp exchange ${Boost_LIBRARIES})

file(GLOB replay-common-sources "core/*.cc" "model/*.cc")

# replay.vpi

file(GLOB replay-vpi-sources "vpi/*.cc")

add_library(replay-vpi SHARED
    ${replay-common-sources}
    ${replay-vpi-sources}
)

set_target_properties(replay-vpi PROPERTIES PREFIX "")
set_target_properties(replay-vpi PROPERTIES SUFFIX ".vpi")

target_include_directories(replay-vpi PRIVATE ${iverilog-include-dir})

target_link_options(replay-vpi PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS replay-vpi
    LIBRARY DESTINATION share/recheck
)

# scdump

add_executable(scdump ${replay-common-sources} tools/scdump.cc)

install(TARGETS scdump
    DESTINATION bin
)

# BitVectorTest

add_executable(BitVectorTest ${replay-common-sources} tests/bitvector_test.cc)

add_test(NAME BitVectorTest COMMAND BitVectorTest)
