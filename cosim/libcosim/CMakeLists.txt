find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(libcosim C)

add_library(cosim_api STATIC lib/ipc/cosim_ipc.c lib/cosim_bfm_api.c)
add_library(cosim_ivl SHARED lib/ipc/cosim_ipc.c lib/cosim_bfm_vpi.c)

target_compile_definitions(cosim_api PRIVATE DEBUG)
target_compile_definitions(cosim_ivl PRIVATE iverilog)

set_target_properties(cosim_ivl PROPERTIES PREFIX "")
set_target_properties(cosim_ivl PROPERTIES SUFFIX ".vpi")

target_include_directories(cosim_api PUBLIC include)
target_include_directories(cosim_ivl PUBLIC include)
target_include_directories(cosim_ivl PRIVATE ${iverilog-include-dir})

target_link_options(cosim_ivl PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(DIRECTORY verilog/
    DESTINATION share/remu/cosim/include
)

install(TARGETS cosim_ivl
    LIBRARY DESTINATION share/remu
)
