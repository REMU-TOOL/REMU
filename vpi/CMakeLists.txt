project(replay)

find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

file(GLOB replay-sources "*.cc")

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
