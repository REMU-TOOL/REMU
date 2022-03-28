cmake_minimum_required (VERSION 3.5)

include(ExternalProject)

project(emulator)

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

# Add iverilog project

set(IVERILOG_TMP_DESTDIR    ${CMAKE_BINARY_DIR}/iverilog_destdir)

set(IVERILOG_ROOT           ${CMAKE_SOURCE_DIR}/iverilog)
set(IVERILOG_INCLUDE_DIR    ${IVERILOG_ROOT})

set(IVERILOG_CONFIGURE      cd ${IVERILOG_ROOT} && sh autoconf.sh && ./configure --prefix=/)
set(IVERILOG_MAKE           cd ${IVERILOG_ROOT} && $(MAKE))
set(IVERILOG_INSTALL        cd ${IVERILOG_ROOT} && $(MAKE) DESTDIR=${IVERILOG_TMP_DESTDIR} install)

ExternalProject_Add(iverilog
    SOURCE_DIR          ${IVERILOG_ROOT}
    CONFIGURE_COMMAND   ${IVERILOG_CONFIGURE}
    BUILD_COMMAND       ${IVERILOG_MAKE}
    INSTALL_COMMAND     ${IVERILOG_INSTALL}
)

install(DIRECTORY ${IVERILOG_TMP_DESTDIR}/
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    USE_SOURCE_PERMISSIONS
)

# Add emulation libraries

install(DIRECTORY ${CMAKE_SOURCE_DIR}/emulib/
    DESTINATION share/yosys/emulib
)

# Add transform project

add_subdirectory(transform)

# Add vpi project

add_subdirectory(vpi)
