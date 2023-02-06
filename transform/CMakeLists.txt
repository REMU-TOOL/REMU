project(transform)

file(GLOB transform-sources "*.cc")

add_library(transform SHARED ${transform-sources})

set_target_properties(transform PROPERTIES PREFIX "")

include_directories(${YOSYS_INCLUDE_DIR})

target_link_libraries(transform PRIVATE common)

target_compile_options(transform PRIVATE
    -Wall -Wextra -Os
)

target_compile_definitions(transform PRIVATE
    _YOSYS_
    YOSYS_ENABLE_READLINE
	YOSYS_ENABLE_PLUGINS
	YOSYS_ENABLE_GLOB
	YOSYS_ENABLE_ZLIB
	YOSYS_ENABLE_ABC
	YOSYS_ENABLE_COVER
)

add_dependencies(transform yosys)

install(TARGETS transform
    LIBRARY DESTINATION share/yosys/plugins
)
