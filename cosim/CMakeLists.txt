project(cosim)

add_subdirectory(libcosim)

install(DIRECTORY verilog/
    DESTINATION share/remu/cosim
)
