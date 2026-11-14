cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)


# ── Service executable target ──────────────────────────────────────────
aw_add_service_executable(__PROJECT_NAME__
    SOURCES src/service/daemon.cpp
    SERVICE_NAME "__PROJECT_NAME__"
    SERVICE_DISPLAY_NAME "__PROJECT_NAME__ Service"
    SERVICE_DESCRIPTION "A long-running service process"
    LINK_LIBRARIES Threads::Threads
)

# ── Examples, Install ─────────────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
