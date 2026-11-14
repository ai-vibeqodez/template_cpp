cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)
include(archetypes/04_executables.cmake)


# ── CLI executable target ──────────────────────────────────────────────
aw_add_executable(__PROJECT_NAME__
    SOURCES src/main.cpp
    LINK_LIBRARIES Threads::Threads
)
target_compile_definitions(__PROJECT_NAME__ PRIVATE
    __PROJECT_UPPER___VERSION="${PROJECT_VERSION}")

# ── Examples, Install ─────────────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
