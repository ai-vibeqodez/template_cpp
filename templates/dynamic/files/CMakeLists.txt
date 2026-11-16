cmake_minimum_required(VERSION 3.21)
project(@@NAME@@ VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(MSVC)
    set(AW_WARNINGS /W4)
else()
    set(AW_WARNINGS -Wall -Wextra -Wpedantic)
endif()

include(GenerateExportHeader)

# Keep the DLL next to the executables (tests) so it is found at run time on Windows.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

add_library(@@NAME@@ SHARED src/@@NAME_ID@@.cpp)
add_library(@@NS@@::@@NAME@@ ALIAS @@NAME@@)
set_target_properties(@@NAME@@ PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})

# Generates @@MACRO_PREFIX@@_API (+ @@MACRO_PREFIX@@_STATIC for consumers that link a static build).
set(AW_EXPORT_HEADER "${CMAKE_CURRENT_BINARY_DIR}/generated/include/@@NS_PATH@@/@@NAME_ID@@_export.hpp")
generate_export_header(@@NAME@@
    EXPORT_MACRO_NAME @@MACRO_PREFIX@@_API
    STATIC_DEFINE     @@MACRO_PREFIX@@_STATIC
    EXPORT_FILE_NAME  "${AW_EXPORT_HEADER}")

target_include_directories(@@NAME@@ PUBLIC
    include
    "${CMAKE_CURRENT_BINARY_DIR}/generated/include")
target_compile_features(@@NAME@@ PUBLIC cxx_std_20)
target_compile_options(@@NAME@@ PRIVATE ${AW_WARNINGS})

# Tests exist only if the project was generated with tests (the tests/ directory is optional).
if(PROJECT_IS_TOP_LEVEL AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
    include(CTest)
    if(BUILD_TESTING)
        add_subdirectory(tests)
    endif()
endif()
