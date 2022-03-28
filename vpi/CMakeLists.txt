project(reconstruct)

file(GLOB reconstruct-sources "*.cc")

add_library(reconstruct SHARED ${reconstruct-sources})

set_target_properties(reconstruct PROPERTIES PREFIX "")
set_target_properties(reconstruct PROPERTIES SUFFIX ".vpi")

include_directories(${IVERILOG_INCLUDE_DIR})

target_link_libraries(reconstruct PRIVATE yaml-cpp)

target_compile_options(reconstruct PRIVATE
    -Wall -Wextra -Wshadow -O2
)

target_link_options(reconstruct PRIVATE
    -lveriuser -lvpi
)

add_dependencies(reconstruct iverilog)

install(TARGETS reconstruct
    LIBRARY DESTINATION lib/ivl
)
