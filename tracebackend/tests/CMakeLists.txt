# 添加可执行文件
add_executable(TraceBackendTest TraceBackendTest.cpp)
add_executable(TraceBatchTest TraceBatchTest.cpp)
add_executable(BatchTest BatchTest.cpp)

# 链接测试可执行文件到库
target_link_libraries(TraceBackendTest TraceBackend)
target_link_libraries(TraceBatchTest TraceBackend)
target_link_libraries(BatchTest TraceBackend bitvector)

# set include directory
find_program(verilator-executable verilator)
get_filename_component(verilator-bin-dir ${verilator-executable} DIRECTORY)
set(verilator-include-dir ${verilator-bin-dir}/../share/verilator/include)
target_include_directories(BatchTest PRIVATE ${verilator-include-dir})
target_include_directories(BatchTest PRIVATE ${verilator-include-dir}/gtkwave)
target_include_directories(BatchTest PRIVATE ${verilator-include-dir}/vltstd)
target_include_directories(BatchTest PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../obj_dir)


# 添加测试
enable_testing()
add_test(NAME TraceBackendTest COMMAND TraceBackendTest)
add_test(NAME TraceBatchTest COMMAND TraceBatchTest)
