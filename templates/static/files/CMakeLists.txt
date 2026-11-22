cmake_minimum_required(VERSION 3.23)

include(FetchContent)
FetchContent_Declare(
    aw_cmake_modules
    GIT_REPOSITORY https://github.com/ai-warevo/template_cpp
    GIT_TAG main
    GIT_SHALLOW ON)
FetchContent_MakeAvailable(aw_cmake_modules)
list(APPEND CMAKE_MODULE_PATH "${aw_cmake_modules_SOURCE_DIR}/cmake")

include(AWProject)
aw_project_prepare(NAME @@NAME@@ NAMESPACE @@NS@@)
project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)
aw_project_setup(PREFIX @@NAME_UPPER@@ BUILD_EXAMPLES BUILD_TESTS INSTALL)

find_package(Threads REQUIRED)
aw_check_cxx23_runtime()

aw_add_library(TARGET @@NAME@@ TYPE STATIC ALIAS @@NS@@
    SOURCES src/@@NAME_ID@@.cpp
    HEADERS include/@@NS_PATH@@/@@NAME_ID@@.hpp
    PUBLIC_INCLUDE_DIRS include
    PUBLIC_LINKS Threads::Threads)

if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    aw_configure_compiler(TARGET @@NAME@@ STRICT_WARNINGS)
endif()

if(@@NAME_UPPER@@_INSTALL)
    aw_install_library(TARGET @@NAME@@ NAME @@NAME@@ NS @@NS@@ DEPENDENCIES Threads)
endif()

if(@@NAME_UPPER@@_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
aw_setup_tests(OPTION @@NAME_UPPER@@_BUILD_TESTS DIRECTORY tests)
