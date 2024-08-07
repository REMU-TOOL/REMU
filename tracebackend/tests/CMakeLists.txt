# verilator use zlib
find_package(ZLIB REQUIRED)

set(test_design Backend Batch)

enable_testing()

foreach(top ${test_design})
    # 添加可执行文件
    add_executable(${top}Gen ${top}Gen.cpp)
    add_executable(${top}Test ${top}Test.cpp)
    # 链接测试可执行文件到库
    target_link_libraries(${top}Gen TraceBackend)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/Vtop.h ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/TracePortMacro.h ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libVtop.a ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libverilated.a
        COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/vxx.sh ${CMAKE_CURRENT_BINARY_DIR}/${top}Gen ${CMAKE_CURRENT_SOURCE_DIR}/design/${top} ${CMAKE_BUILD_PARALLEL_LEVEL}
        DEPENDS ${top}Gen
    )
    add_custom_target(
        ${top}vheader ALL
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/Vtop.h ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/TracePortMacro.h ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libVtop.a ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libverilated.a
    )
    # decalre verilator generated lib
    add_library(libV${top} STATIC IMPORTED)
    set_target_properties(libV${top} PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libVtop.a)

    add_library(libverilated${top} STATIC IMPORTED)
    set_target_properties(libverilated${top} PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/design/${top}/libverilated.a)

    add_dependencies(${top}Test ${top}vheader)
    target_link_libraries(${top}Test TraceBackend common bitvector libV${top} libverilated${top} ZLIB::ZLIB)


    # set BatchTest include directory
    find_program(verilator-executable verilator)
    get_filename_component(verilator-bin-dir ${verilator-executable} DIRECTORY)
    set(verilator-include-dir ${verilator-bin-dir}/../share/verilator/include)
    target_include_directories(${top}Test PRIVATE ${verilator-include-dir})
    target_include_directories(${top}Test PRIVATE ${verilator-include-dir}/gtkwave)
    target_include_directories(${top}Test PRIVATE ${verilator-include-dir}/vltstd)

    add_test(NAME ${top}Test COMMAND ${top}Test +dumpfile=wave.fst +duration=1024)
endforeach()

