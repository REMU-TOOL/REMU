project(trace_parser)

file(GLOB parser_sources "*.cc")
add_executable(remu-tparser ${parser_sources})

target_link_libraries(remu-tparser common tokenizer)

install(TARGETS remu-tparser
    DESTINATION bin
)
