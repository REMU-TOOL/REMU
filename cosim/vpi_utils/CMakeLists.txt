find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(vpi_utils)

add_library(vpi_utils INTERFACE)

target_include_directories(vpi_utils INTERFACE .)
target_include_directories(vpi_utils INTERFACE ${iverilog-include-dir})

target_link_libraries(vpi_utils INTERFACE bitvector)
