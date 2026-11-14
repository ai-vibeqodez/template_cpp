cmake_minimum_required(VERSION 3.23)

# Single source of truth for the version; written by scripts/release.sh / release.ps1.
file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
             "${CMAKE_CURRENT_LIST_DIR}/VERSION")

project(template_cpp VERSION ${PROJECT_VERSION} LANGUAGES CXX)

# Dependencies
find_package(Threads REQUIRED)

# Set project prefix for AwProjectDefaults (must be before include)
set(AW_PROJECT_PREFIX "TEMPLATE_CPP")

# Include shared CMake infrastructure
include(cmake/AwProjectDefaults.cmake)

# ── Load archetype helpers ─────────────────────────────────────────────
include(archetypes/01_core.cmake)
include(archetypes/02_shared_plugin.cmake)
include(archetypes/03_modules.cmake)
include(archetypes/04_executables.cmake)
include(archetypes/05_service.cmake)
include(archetypes/06_kernel.cmake)

# ── Library target (delegated to archetype helpers, full impl in Task 02) ─
aw_add_static_library(${PROJECT_NAME}
    SOURCES src/hello.cpp
    HEADERS include/aw/template_cpp/hello.hpp
    LINK_LIBRARIES Threads::Threads
)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    TEMPLATE_CPP_VERSION="${PROJECT_VERSION}")

# ── Examples, Tests, Install (using public helpers) ──────────────────
option(AW_TEMPLATE_CPP_BUILD_EXAMPLES
       "Build aw::template_cpp example applications" ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})

if(AW_TEMPLATE_CPP_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW_TEMPLATE_CPP_BUILD_TESTS
       "Build aw::template_cpp unit tests" ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})

if(AW_TEMPLATE_CPP_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

option(AW_TEMPLATE_CPP_INSTALL
       "Generate install rules and package config" ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})
