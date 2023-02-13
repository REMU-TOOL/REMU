find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(fastarray)

add_library(fastarray_ivl SHARED fastarray_vpi.cc)

set_target_properties(fastarray_ivl PROPERTIES PREFIX "")
set_target_properties(fastarray_ivl PROPERTIES SUFFIX ".vpi")

target_include_directories(fastarray_ivl PRIVATE ${iverilog-include-dir})

target_link_libraries(fastarray_ivl vpi_utils)

target_link_options(fastarray_ivl PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS fastarray_ivl
    LIBRARY DESTINATION share/remu
)
