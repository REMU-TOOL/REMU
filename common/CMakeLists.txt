project(common)

set(CMAKE_CXX_STANDARD 17)

file(GLOB common-sources "*.cc")

add_library(common STATIC ${common-sources})
target_include_directories(common PUBLIC ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(common bitvector cereal)
