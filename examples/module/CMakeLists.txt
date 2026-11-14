cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)

include(archetypes/01_core.cmake)
include(archetypes/02_shared_plugin.cmake)
include(archetypes/03_modules.cmake)
include(archetypes/04_executables.cmake)
include(archetypes/05_service.cmake)
include(archetypes/06_kernel.cmake)

# ── C++20 module library target ────────────────────────────────────────
aw_add_cxx_module_library(__PROJECT_NAME__
    MODULES
        src/__PROJECT__.cppm
    HEADERS
        include/aw/__PROJECT__/__PROJECT__.h
    LINK_LIBRARIES
        Threads::Threads
    COMPILE_DEFINITIONS
        __PROJECT_UPPER___VERSION="1.0.0"
    MODULE_NAME
        __PROJECT_NAME__
)

# ── Examples, Tests, Install ──────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___BUILD_TESTS
       "Build unit tests" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
