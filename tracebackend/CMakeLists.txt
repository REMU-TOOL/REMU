cmake_minimum_required (VERSION 3.5)

project(TraceBackend VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# 包含include目录
include_directories(include)

# 添加子目录
add_subdirectory(src)
add_subdirectory(tests)
