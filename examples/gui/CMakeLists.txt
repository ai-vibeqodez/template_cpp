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

# ── GUI executable target ──────────────────────────────────────────────
# Platform-specific setup
if(WIN32)
    aw_add_gui_executable(__PROJECT_NAME__
        SOURCES src/gui/main.cpp
        APP_NAME "__PROJECT_NAME__"
    )
elseif(APPLE)
    aw_add_gui_executable(__PROJECT_NAME__
        SOURCES src/gui/main.cpp
        APP_NAME "__PROJECT_NAME__"
    )
else()
    aw_add_gui_executable(__PROJECT_NAME__
        SOURCES src/gui/main.cpp
        APP_NAME "__PROJECT_NAME__"
    )
endif()

# ── Examples, Install ─────────────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
