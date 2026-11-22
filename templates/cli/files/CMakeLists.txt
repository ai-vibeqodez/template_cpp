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
aw_project_setup(PREFIX @@NAME_UPPER@@ BUILD_TESTS)
aw_check_cxx23_runtime()

include(CoreLibrary)
aw_core_library(NAME @@NAME@@ ID @@NAME_ID@@)
aw_add_executable(TARGET @@NAME@@ SOURCES src/main.cpp
    LINK_LIBRARIES @@NS@@::@@NAME@@_core)

if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    aw_configure_compiler(TARGET @@NAME@@ STRICT_WARNINGS)
endif()
aw_setup_tests(OPTION @@NAME_UPPER@@_BUILD_TESTS DIRECTORY tests)
