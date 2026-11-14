cmake_minimum_required(VERSION 3.23)

# Single source of truth for the version.
file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

# Dependencies
find_package(Threads REQUIRED)

# Set project prefix for AwProjectDefaults
set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

# Include shared CMake infrastructure
include(cmake/AwProjectDefaults.cmake)

# ── Load archetype helpers ─────────────────────────────────────────────
include(archetypes/01_core.cmake)
include(archetypes/02_shared_plugin.cmake)
include(archetypes/03_modules.cmake)
include(archetypes/04_executables.cmake)
include(archetypes/05_service.cmake)
include(archetypes/06_kernel.cmake)

# ── Library target ─────────────────────────────────────────────────────
aw_add_static_library(__PROJECT_NAME__
    SOURCES src/__PROJECT__.cpp
    HEADERS include/aw/__PROJECT__/__PROJECT__.hpp
    LINK_LIBRARIES Threads::Threads
)
target_compile_definitions(__PROJECT_NAME__ PRIVATE
    __PROJECT_UPPER___VERSION="${PROJECT_VERSION}")

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
