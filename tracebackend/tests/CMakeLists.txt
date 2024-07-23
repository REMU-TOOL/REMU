# 添加可执行文件
add_executable(BackendGen BackendGen.cpp)
add_executable(BatchGen BatchGen.cpp)
add_executable(BatchTest BatchTest.cpp)

# 链接测试可执行文件到库
target_link_libraries(BackendGen TraceBackend)
target_link_libraries(BatchGen TraceBackend)


add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/Vtop.h ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/TracePortDef.h ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libVtop.a ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libverilated.a
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/vxx.sh ${CMAKE_CURRENT_BINARY_DIR}/BatchGen ${CMAKE_CURRENT_SOURCE_DIR}/design/batch ${CMAKE_BUILD_PARALLEL_LEVEL}
    DEPENDS BatchGen
)

# 自定义目标，依赖于自定义命令生成的文件
add_custom_target(
    vheader ALL
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/Vtop.h ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/TracePortDef.h ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libVtop.a ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libverilated.a
)

# decalre verilator generated lib
add_library(Vtop STATIC IMPORTED)
set_target_properties(Vtop PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libVtop.a)

add_library(verilated STATIC IMPORTED)
set_target_properties(verilated PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/libverilated.a)

# verilator use zlib
find_package(ZLIB REQUIRED)
add_dependencies(BatchTest vheader)
target_link_libraries(BatchTest TraceBackend bitvector Vtop verilated ZLIB::ZLIB)

# set BatchTest include directory
find_program(verilator-executable verilator)
get_filename_component(verilator-bin-dir ${verilator-executable} DIRECTORY)
set(verilator-include-dir ${verilator-bin-dir}/../share/verilator/include)
target_include_directories(BatchTest PRIVATE ${verilator-include-dir})
target_include_directories(BatchTest PRIVATE ${verilator-include-dir}/gtkwave)
target_include_directories(BatchTest PRIVATE ${verilator-include-dir}/vltstd)
target_include_directories(BatchTest PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../obj_dir)


# 添加测试
enable_testing()
add_test(NAME BackendGen COMMAND BackendGen)
add_test(NAME BatchGen COMMAND BatchGen)
