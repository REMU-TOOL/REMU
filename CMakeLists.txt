cmake_minimum_required (VERSION 3.5)

include(ExternalProject)

project(remu)

option(ENABLE_REMU_COSIM "enable co-simulation feature in REMU" OFF)

enable_testing()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add cereal project

set(JUST_INSTALL_CEREAL ON)
add_subdirectory(cereal)

# Add yaml-cpp project

add_subdirectory(yaml-cpp)

# Add yosys project

set(YOSYS_TMP_DESTDIR   ${CMAKE_BINARY_DIR}/yosys_destdir)

set(YOSYS_ROOT          ${CMAKE_SOURCE_DIR}/yosys)
set(YOSYS_INCLUDE_DIR   ${YOSYS_ROOT})

set(YOSYS_CONFIGURE     cp ${CMAKE_SOURCE_DIR}/yosys.conf ${YOSYS_ROOT}/Makefile.conf)
set(YOSYS_MAKE          cd ${YOSYS_ROOT} && $(MAKE) DEBUG=$<CONFIG:Debug>)
set(YOSYS_INSTALL       cd ${YOSYS_ROOT} && $(MAKE) DESTDIR=${YOSYS_TMP_DESTDIR} PREFIX=${CMAKE_INSTALL_PREFIX} install)

ExternalProject_Add(yosys
    SOURCE_DIR          ${YOSYS_ROOT}
    CONFIGURE_COMMAND   ${YOSYS_CONFIGURE}
    BUILD_COMMAND       ${YOSYS_MAKE}
    INSTALL_COMMAND     ${YOSYS_INSTALL}
)

install(DIRECTORY ${YOSYS_TMP_DESTDIR}/${CMAKE_INSTALL_PREFIX}/
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    USE_SOURCE_PERMISSIONS
)

# Install individual files

install(PROGRAMS ${CMAKE_SOURCE_DIR}/remu-config.sh DESTINATION bin RENAME remu-config)

# Add emulation libraries

install(DIRECTORY ${CMAKE_SOURCE_DIR}/emulib/
    DESTINATION share/remu/emulib
)

add_subdirectory(bitvector)
add_subdirectory(common)
add_subdirectory(driver)
add_subdirectory(replay)
add_subdirectory(tokenizer)
add_subdirectory(tools)
add_subdirectory(transform)
add_subdirectory(vpi_utils)
add_subdirectory(tracebackend)

if(${ENABLE_REMU_COSIM})
    add_subdirectory(cosim)
endif()
