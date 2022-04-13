project(replay)

find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

file(GLOB replay-sources "*.cc")

add_library(replay SHARED ${replay-sources})

set_target_properties(replay PROPERTIES PREFIX "")
set_target_properties(replay PROPERTIES SUFFIX ".vpi")

add_dependencies(replay iverilog)

include_directories(${IVL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

target_link_libraries(replay PRIVATE
    yaml-cpp
    ${Boost_LIBRARIES}
)

target_compile_options(replay PRIVATE
    -Wall -Wextra -Wshadow -O2
)

target_link_options(replay PRIVATE
    -L${IVL_TMP_DESTDIR}/lib
    -lveriuser -lvpi
)

install(TARGETS replay
    LIBRARY DESTINATION share/recheck
)
