project(remu_driver)

file(GLOB driver_sources "*.cc")

add_executable(remu-driver ${driver_sources})

target_link_libraries(remu-driver common cosim_api yaml-cpp)

install(TARGETS remu-driver
    DESTINATION bin
)
