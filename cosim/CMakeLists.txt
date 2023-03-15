find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(libcosim)

find_package(Boost REQUIRED)
include_directories(${BOOST_INCLUDE_DIRS})

add_library(cosim_api STATIC cosim.cc)
add_library(cosim_ivl SHARED cosim.cc cosim_vpi.cc)

set_target_properties(cosim_ivl PROPERTIES PREFIX "")
set_target_properties(cosim_ivl PROPERTIES SUFFIX ".vpi")

target_include_directories(cosim_api PUBLIC .)
target_include_directories(cosim_ivl PUBLIC .)
target_include_directories(cosim_ivl PRIVATE ${iverilog-include-dir})

target_link_libraries(cosim_ivl vpi_utils)

target_link_options(cosim_ivl PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS cosim_ivl
    LIBRARY DESTINATION share/remu
)
