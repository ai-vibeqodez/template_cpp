cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

find_package(Threads REQUIRED)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)


# ── Shared library target ──────────────────────────────────────────────
aw_add_shared_library(__PROJECT_NAME__
    SOURCES src/__PROJECT__.cpp
            src/DllMain.cpp
            src/init.cpp
    HEADERS include/aw/__PROJECT__/__PROJECT__.hpp
            include/aw/__PROJECT__/export_macro.hpp
    LINK_LIBRARIES Threads::Threads
)
target_compile_definitions(__PROJECT_NAME__ PRIVATE
    __PROJECT_UPPER___BUILDING
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
