project(scdump)

file(GLOB scdump_sources "*.cc")
add_executable(remu-scdump ${scdump_sources})

target_link_libraries(remu-scdump common)

install(TARGETS remu-scdump
    DESTINATION bin
)
