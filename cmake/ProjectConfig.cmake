# aw_project_config()
#
# Base project configuration: version from file, C++23, compiler warnings.
#
# Usage:
#   include(cmake/ProjectConfig)
#   aw_project_config(NAME MyLib NS aw::)
#   project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)
#
# Sets: AW_PROJECT_NAME, AW_PROJECT_VERSION, AW_WARNINGS,
#       CMAKE_CXX_STANDARD, CMAKE_CXX_STANDARD_REQUIRED,
#       CMAKE_CXX_EXTENSIONS, CMAKE_EXPORT_COMPILE_COMMANDS, _NS

# Ensure cmake/ modules are findable when included from the root CMakeLists.txt.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

function(aw_project_config)
    set(_oneValue NAME NS VERSION_FILE)
    set(_multiValue)
    cmake_parse_arguments(_CFG "${_multiValue}" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _CFG_NAME)
        message(FATAL_ERROR "aw_project_config() requires NAME argument")
    endif()
    if(NOT _CFG_NS)
        message(FATAL_ERROR "aw_project_config() requires NS argument")
    endif()

    # --- Version from file (single source of truth) ---
    if(_CFG_VERSION_FILE)
        set(_version_file "${_CFG_VERSION_FILE}")
    else()
        set(_version_file "${CMAKE_CURRENT_LIST_DIR}/VERSION")
    endif()

    file(READ "${_version_file}" _aw_version_raw)
    string(STRIP "${_aw_version_raw}" _aw_version)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_version_file}")

    # --- C++23 ---
    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # --- Compiler warnings (base level) ---
    # AW_WARNINGS: applied to all targets (library + tests)
    # AW_STRICT_WARNINGS: opt-in -Werror for library only (set by caller after project())
    #
    # NOTE: This function runs BEFORE project(), so CMAKE_CXX_COMPILER_ID is empty.
    # Detect compiler from CMAKE_CXX_COMPILER path (set by toolchain or environment).
    set(_aw_compiler "${CMAKE_CXX_COMPILER}")
    if(_aw_compiler MATCHES "(^|[/\\\\])cl($|[/\\\\]|\\.)" OR DEFINED ENV{VSCMD_APP_ATMOSPHERE})
        set(AW_WARNINGS /W4 PARENT_SCOPE)
        set(AW_STRICT_WARNINGS /WX PARENT_SCOPE)
    else()
        set(AW_WARNINGS -Wall -Wextra -Wpedantic PARENT_SCOPE)
        set(AW_STRICT_WARNINGS -Wshadow -Wconversion -Werror PARENT_SCOPE)
    endif()
    unset(_aw_compiler)

    # Export values to caller scope so root CMakeLists.txt can call project().
    set(AW_PROJECT_NAME    "${_CFG_NAME}"    PARENT_SCOPE)
    set(AW_PROJECT_VERSION "${_aw_version}"  PARENT_SCOPE)
    set(_NS                "${_CFG_NS}"      PARENT_SCOPE)
    set(CMAKE_CXX_STANDARD 23 PARENT_SCOPE)
    set(CMAKE_CXX_STANDARD_REQUIRED ON PARENT_SCOPE)
    set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON PARENT_SCOPE)
endfunction()
