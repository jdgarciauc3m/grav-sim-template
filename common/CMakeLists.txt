add_library(common STATIC)
target_sources(common PRIVATE
    src/progargs.cpp
    include/point.hpp
)

target_include_directories(common PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)