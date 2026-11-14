cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES C)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)


# ── Kernel driver target (Linux module) ────────────────────────────────
aw_add_kernel_driver(__PROJECT_NAME__
    SOURCES src/kernel/module.c
    PLATFORM linux
    MODULE_NAME "__PROJECT_NAME__"
    LINUX_VERSION 6.6
)

# ── Examples, Install ─────────────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
