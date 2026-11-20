cmake_minimum_required(VERSION 3.23)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(cmake/ProjectConfig)
aw_project_config(NAME @@NAME@@ NS @@NS@@)
project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)

# Top-level builds get tests and examples by default; consumers (FetchContent / add_subdirectory) do not.
if(PROJECT_IS_TOP_LEVEL)
    set(@@NAME_UPPER@@_IS_TOP_LEVEL ON)
else()
    set(@@NAME_UPPER@@_IS_TOP_LEVEL OFF)
endif()

option(@@NAME_UPPER@@_BUILD_TESTS "Build @@NAME@@ unit tests" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_BUILD_EXAMPLES "Build @@NAME@@ examples" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_INSTALL "Generate install rules and package config for @@NS@@" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_WARNINGS_AS_ERRORS "Build @@NAME@@ with strict warnings treated as errors" OFF)

# Compiler warnings (must come after project() so CMAKE_CXX_COMPILER_ID is known).
# AW_WARNINGS is shared with the tests; AW_STRICT_WARNINGS (opt-in -Werror) only applies to the library and examples.
if(MSVC)
    set(AW_WARNINGS /W4)
    set(AW_STRICT_WARNINGS /WX)
else()
    set(AW_WARNINGS -Wall -Wextra -Wpedantic)
    set(AW_STRICT_WARNINGS -Wshadow -Wconversion -Werror)
endif()
if(NOT @@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    set(AW_STRICT_WARNINGS "")
endif()

# Public dependencies go here; mirror them in DEPENDENCIES of aw_install_library() below, e.g.
#   find_package(Threads REQUIRED)  ->  target_link_libraries(@@NAME@@ PUBLIC Threads::Threads)  +  DEPENDENCIES Threads
add_library(@@NAME@@ STATIC src/@@NAME_ID@@.cpp)
# The alias is the namespace itself (e.g. NS=aw::tpl -> aw::tpl), so it only fits namespaces that end in the project name.
add_library(@@NS@@ ALIAS @@NAME@@)
target_compile_features(@@NAME@@ PUBLIC cxx_std_23)
target_compile_options(@@NAME@@ PRIVATE ${AW_WARNINGS} ${AW_STRICT_WARNINGS})
target_sources(@@NAME@@
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS include
        FILES
            include/@@NS_PATH@@/@@NAME_ID@@.hpp
)

if(@@NAME_UPPER@@_INSTALL)
    include(cmake/Library/InstallExport)
    aw_install_library(NAME @@NAME@@ NS @@NS@@ DEPENDENCIES)
endif()

# Tests and examples exist only if the project was generated with them (the directories are optional).
if(@@NAME_UPPER@@_BUILD_EXAMPLES AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples/CMakeLists.txt")
    add_subdirectory(examples)
endif()

if(@@NAME_UPPER@@_BUILD_TESTS AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
    include(CTest)
    add_subdirectory(tests)
endif()
