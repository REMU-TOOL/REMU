# 添加可执行文件
add_executable(BackendGen BackendGen.cpp)
add_executable(BatchGen BatchGen.cpp)
add_executable(BatchTest BatchTest.cpp)

# 链接测试可执行文件到库
target_link_libraries(BackendGen TraceBackend)
target_link_libraries(BatchGen TraceBackend)

target_link_libraries(BatchTest TraceBackend bitvector)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/Vtop.h # ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/TracePortDef.h
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/vxx.sh batch ${CMAKE_CURRENT_BINARY_DIR}/BatchGen ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/top.v
    DEPENDS BatchGen
)

# 自定义目标，依赖于自定义命令生成的文件
add_custom_target(
    vheader ALL
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/design/batch/Vtop.h
)

add_dependencies(BatchTest vheader)

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
