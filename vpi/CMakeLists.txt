find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

project(replay)

file(GLOB replay-sources "*.cc")
list(REMOVE_ITEM replay-sources "scdump.cc")

add_library(replay SHARED ${replay-sources})

set_target_properties(replay PROPERTIES PREFIX "")
set_target_properties(replay PROPERTIES SUFFIX ".vpi")

find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)

include_directories(${iverilog-bin-dir}/../include/iverilog)
include_directories(${Boost_INCLUDE_DIRS})

target_link_libraries(replay PRIVATE
    yaml-cpp
    ${Boost_LIBRARIES}
)

target_link_options(replay PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS replay
    LIBRARY DESTINATION share/recheck
)

project(scdump)

add_executable(scdump
    scdump.cc
    loader.cc
    checkpoint.cc
)

include_directories(${Boost_INCLUDE_DIRS})

target_link_libraries(scdump PRIVATE
    yaml-cpp
    ${Boost_LIBRARIES}
)

install(TARGETS scdump
    DESTINATION bin
)
