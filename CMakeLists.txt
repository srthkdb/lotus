cmake_minimum_required(VERSION 3.16)
project(lotus)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

add_compile_definitions(SHADER_ROOT="${CMAKE_SOURCE_DIR}/lotus/src/shaders/")

# Build libraries
add_subdirectory(lotus)
add_subdirectory(examples/quickstart)
# add_subdirectory(docs)

#if (BUILD_DOCS)
#    add_subdirectory(docs)
#endif()
