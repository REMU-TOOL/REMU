find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(vpi_utils)

add_library(vpi_utils STATIC vpi_utils.cc)

target_include_directories(vpi_utils PUBLIC .)
target_include_directories(vpi_utils PUBLIC ${iverilog-include-dir})

target_link_libraries(vpi_utils bitvector)
