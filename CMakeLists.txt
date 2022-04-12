cmake_minimum_required (VERSION 3.5)

include(ExternalProject)

project(recheck)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add yaml-cpp project

add_subdirectory(yaml-cpp)

# Add yosys project

set(YOSYS_TMP_DESTDIR   ${CMAKE_BINARY_DIR}/yosys_destdir)

set(YOSYS_ROOT          ${CMAKE_SOURCE_DIR}/yosys)
set(YOSYS_INCLUDE_DIR   ${YOSYS_ROOT})

set(YOSYS_CONFIGURE     cp ${CMAKE_SOURCE_DIR}/yosys.conf ${YOSYS_ROOT}/Makefile.conf)
set(YOSYS_MAKE          cd ${YOSYS_ROOT} && $(MAKE))
set(YOSYS_INSTALL       cd ${YOSYS_ROOT} && $(MAKE) DESTDIR=${YOSYS_TMP_DESTDIR} PREFIX= install)

ExternalProject_Add(yosys
    SOURCE_DIR          ${YOSYS_ROOT}
    CONFIGURE_COMMAND   ${YOSYS_CONFIGURE}
    BUILD_COMMAND       ${YOSYS_MAKE}
    INSTALL_COMMAND     ${YOSYS_INSTALL}
)

install(DIRECTORY ${YOSYS_TMP_DESTDIR}/
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    USE_SOURCE_PERMISSIONS
)

# Install separate files

install(PROGRAMS ${CMAKE_SOURCE_DIR}/recheck.sh DESTINATION bin RENAME recheck)
install(FILES ${CMAKE_SOURCE_DIR}/recheck.tcl DESTINATION share/recheck)

# Add emulation libraries

install(DIRECTORY ${CMAKE_SOURCE_DIR}/emulib/
    DESTINATION share/recheck/emulib
)

# Add transform project

add_subdirectory(transform)

# Add vpi project

add_subdirectory(vpi)
