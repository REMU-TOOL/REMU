project(remu_driver)

file(GLOB driver_sources "*.cc")

add_executable(remu-driver ${driver_sources})

target_link_libraries(remu-driver common yaml-cpp tokenizer readline)

if(${ENABLE_REMU_COSIM})
    target_compile_definitions(remu-driver PRIVATE ENABLE_COSIM)
    target_link_libraries(remu-driver cosim_api)
endif()

install(TARGETS remu-driver
    DESTINATION bin
)
