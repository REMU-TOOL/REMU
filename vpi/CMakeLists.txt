project(reconstruct)

find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

file(GLOB reconstruct-sources "*.cc")

add_library(reconstruct SHARED ${reconstruct-sources})

set_target_properties(reconstruct PROPERTIES PREFIX "")
set_target_properties(reconstruct PROPERTIES SUFFIX ".vpi")

find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)

include_directories(${iverilog-bin-dir}/../include/iverilog)
include_directories(${Boost_INCLUDE_DIRS})

target_link_libraries(reconstruct PRIVATE
    yaml-cpp
    ${Boost_LIBRARIES}
)

target_compile_options(reconstruct PRIVATE
    -Wall -Wextra -Wshadow -O2
)

target_link_options(reconstruct PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS reconstruct
    LIBRARY DESTINATION share/recheck
)
