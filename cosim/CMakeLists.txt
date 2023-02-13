project(cosim)

add_subdirectory(fastarray)
add_subdirectory(libcosim)
add_subdirectory(vpi_utils)

install(DIRECTORY verilog/
    DESTINATION share/remu/cosim
)
