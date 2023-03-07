find_program(iverilog-executable iverilog)
get_filename_component(iverilog-bin-dir ${iverilog-executable} DIRECTORY)
set(iverilog-include-dir ${iverilog-bin-dir}/../include/iverilog)

project(replay)

file(GLOB replay_ivl_sources "*.cc")

add_library(replay_ivl SHARED
    ${replay_ivl_sources}
)

set_target_properties(replay_ivl PROPERTIES PREFIX "")
set_target_properties(replay_ivl PROPERTIES SUFFIX ".vpi")

target_include_directories(replay_ivl PRIVATE ${iverilog-include-dir})

target_link_libraries(replay_ivl common vpi_utils)

target_link_options(replay_ivl PRIVATE
    -L${iverilog-bin-dir}/../lib
    -lveriuser -lvpi
)

install(TARGETS replay_ivl
    LIBRARY DESTINATION share/remu
)
