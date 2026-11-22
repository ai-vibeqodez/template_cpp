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
aw_project_setup(PREFIX @@NAME_UPPER@@ BUILD_TESTS INSTALL)
aw_check_cxx23_runtime()
include(GenerateExportHeader)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(AW_EXPORT_HEADER "${CMAKE_CURRENT_BINARY_DIR}/generated/include/@@NS_PATH@@/@@NAME_ID@@_export.hpp")

set(_@@NAME_ID@@_target_options)
if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    list(APPEND _@@NAME_ID@@_target_options STRICT_WARNINGS)
endif()

aw_add_library(TARGET @@NAME@@ TYPE SHARED ALIAS @@NS@@::@@NAME@@
    SOURCES src/@@NAME_ID@@.cpp
    HEADERS include/@@NS_PATH@@/@@NAME_ID@@.hpp
    PUBLIC_INCLUDE_DIRS include "${CMAKE_CURRENT_BINARY_DIR}/generated/include"
    ${_@@NAME_ID@@_target_options})
set_target_properties(@@NAME@@ PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})
generate_export_header(@@NAME@@
    EXPORT_MACRO_NAME @@MACRO_PREFIX@@_API
    STATIC_DEFINE @@MACRO_PREFIX@@_STATIC
    EXPORT_FILE_NAME "${AW_EXPORT_HEADER}")

if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    aw_configure_compiler(TARGET @@NAME@@ STRICT_WARNINGS)
endif()
if(@@NAME_UPPER@@_INSTALL)
    aw_install_library(TARGET @@NAME@@ NAME @@NAME@@ NS @@NS@@ DEPENDENCIES)
    install(FILES "${AW_EXPORT_HEADER}" DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/@@NS_PATH@@")
endif()
aw_setup_tests(OPTION @@NAME_UPPER@@_BUILD_TESTS DIRECTORY tests)
