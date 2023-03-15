project(tokenizer)

file(GLOB tokenizer_sources "*.cc")
add_library(tokenizer STATIC ${tokenizer_sources})
target_include_directories(tokenizer PUBLIC .)
