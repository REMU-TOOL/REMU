file(GLOB SOURCES "*.cpp")

find_package(fmt)

add_library(TraceBackend ${SOURCES})

file(GLOB VSRC "../resources/*.v")
foreach(file ${VSRC})
    # 去掉旧前缀
    string(REPLACE "../resources/" "vtemplate/" file_src_vtemplate ${file})
    
    # 替换旧后缀为新后缀
    string(REPLACE ".v" ".inc" inc_file ${file_src_vtemplate})
    list(APPEND INC_SRC ${inc_file})
endforeach()

# 自定义命令生成 inc 文件
add_custom_command(
    OUTPUT  ${INC_SRC}
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/RewriteDirectory.sh ${CMAKE_CURRENT_SOURCE_DIR}/../resources ${CMAKE_CURRENT_SOURCE_DIR}/vtemplate
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/RewriteDirectory.sh ${VSRC}
)

# 自定义目标，依赖于自定义命令生成的文件
add_custom_target(
    generate_files_target ALL
    DEPENDS ${INC_SRC}
)

add_dependencies(TraceBackend generate_files_target)

target_link_libraries(TraceBackend fmt::fmt)

target_include_directories(TraceBackend PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../include)
