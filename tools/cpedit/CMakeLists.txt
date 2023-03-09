project(cpedit)

file(GLOB cpedit_sources "*.cc")
add_executable(remu-cpedit ${cpedit_sources})

target_link_libraries(remu-cpedit common readline)

install(TARGETS remu-cpedit
    DESTINATION bin
)
