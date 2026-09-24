add_executable(grav-soa)
target_sources(grav-soa PRIVATE 
    src/main.cpp
#    include/file1.hpp
#    src/file1.cpp
#    include/file2.hpp
#    src/file2.cpp
)

target_include_directories(grav-soa PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)

target_link_libraries(grav-soa PRIVATE project_warnings GSL common)