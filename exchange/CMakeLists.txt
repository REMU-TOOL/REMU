find_package(Boost 1.36.0 REQUIRED COMPONENTS filesystem iostreams)

project(exchange)

file(GLOB exchange-sources "*.cc")

add_library(exchange STATIC ${exchange-sources})

target_include_directories(exchange PUBLIC ${PROJECT_SOURCE_DIR}/include)

target_link_libraries(exchange yaml-cpp ${Boost_LIBRARIES})
