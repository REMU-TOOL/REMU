project(tools)

file(GLOB scdump_sources "scdump/*.cc")
add_executable(scdump ${scdump_sources})

target_link_libraries(scdump common)

install(TARGETS scdump
    DESTINATION bin
)
