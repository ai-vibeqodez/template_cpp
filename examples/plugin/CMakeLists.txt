cmake_minimum_required(VERSION 3.23)

file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)

project(__PROJECT_NAME__ VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(AW_PROJECT_PREFIX "__PROJECT_UPPER__")

include(cmake/AwProjectDefaults.cmake)
include(archetypes/02_shared_plugin.cmake)


# ── Plugin module target ───────────────────────────────────────────────
aw_add_plugin_module(__PROJECT_NAME__
    SOURCES src/__PROJECT__.cpp
    HEADERS include/aw/__PROJECT__/plugin_interface.hpp
    LINK_LIBRARIES __PROJECT_UPPER___SHARED_LIB
    FACTORY_NAME create___PROJECT__
)

# ── Examples, Install ─────────────────────────────────────────────────
option(AW___PROJECT_UPPER___BUILD_EXAMPLES
       "Build examples" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})

if(AW___PROJECT_UPPER___BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW___PROJECT_UPPER___INSTALL
       "Generate install rules" ${AW___PROJECT_UPPER___IS_TOP_LEVEL})
