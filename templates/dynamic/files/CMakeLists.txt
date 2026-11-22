cmake_minimum_required(VERSION 3.23)

# --- Fetch reusable CMake modules from template repository ---
include(FetchContent)

FetchContent_Declare(
    aw_cmake_modules
    GIT_REPOSITORY https://github.com/ai-warevo/template_cpp
    GIT_TAG main
    GIT_SHALLOW ON
)

# For local development: set FETCHCONTENT_SOURCE_DIR_AW_CMAKE_MODULES to ../template_cpp
FetchContent_MakeAvailable(aw_cmake_modules)

# Add remote cmake directory to module search path
list(APPEND CMAKE_MODULE_PATH "${aw_cmake_modules_SOURCE_DIR}/cmake")

# --- Project configuration (all from remote) ---
include(ProjectConfig)

aw_project_config(NAME @@NAME@@ NS @@NS@@)

project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)
aw_configure_warnings()

# --- Additional cmake modules (must come after project()) ---
include(CXX23Runtime)
include(Compiler)

# Check C++23 runtime support
aw_check_cxx23_runtime()

# --- Top-level detection and basic setup ---
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(@@NAME_UPPER@@_IS_TOP_LEVEL ON)
else()
    set(@@NAME_UPPER@@_IS_TOP_LEVEL OFF)
endif()

# --- Options ---
option(@@NAME_UPPER@@_BUILD_EXAMPLES "Build @@NAME@@ example applications" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_BUILD_TESTS "Build @@NAME@@ unit tests" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_INSTALL "Generate install rules and package config for @@NS@@" ${@@NAME_UPPER@@_IS_TOP_LEVEL})
option(@@NAME_UPPER@@_WARNINGS_AS_ERRORS "Build @@NAME@@ with strict warnings treated as errors" OFF)
option(AW_ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
set(AW_SANITIZE "none" CACHE STRING "Sanitizer to enable: none, address (ASan+UBSan) or thread (TSan)")
set_property(CACHE AW_SANITIZE PROPERTY STRINGS none address thread)

# --- Sanitizer/coverage validation ---
if(NOT AW_SANITIZE STREQUAL "none")
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(FATAL_ERROR "AW_SANITIZE requires GCC or Clang")
    endif()
    if(AW_ENABLE_COVERAGE)
        message(FATAL_ERROR "AW_SANITIZE cannot be combined with AW_ENABLE_COVERAGE")
    endif()
endif()

# --- Shared library ---
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
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated/include>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(@@NAME@@ PUBLIC cxx_std_23)

# Register public headers with FILE_SET (CMake 3.23+)
target_sources(@@NAME@@
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS include
        FILES
            include/@@NS_PATH@@/@@NAME_ID@@.hpp
)

# Apply compiler-specific configuration
if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    aw_configure_compiler(TARGET @@NAME@@ STRICT_WARNINGS)
else()
    aw_configure_compiler(TARGET @@NAME@@)
endif()

# --- Install & Package Export ---
if(@@NAME_UPPER@@_INSTALL)
    include(Library/InstallExport)
    aw_install_library(TARGET @@NAME@@ NAME @@NAME@@ NS @@NS@@ DEPENDENCIES)
endif()

# --- Tests ---
if(@@NAME_UPPER@@_BUILD_TESTS)
    include(Tests)  # From remote
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
        include(CTest)
        if(BUILD_TESTING)
            add_subdirectory(tests)
        endif()
    endif()
endif()
