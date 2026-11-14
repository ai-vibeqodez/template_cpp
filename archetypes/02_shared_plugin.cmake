# =============================================================================
# 02_shared_plugin.cmake — Shared library and plugin module archetypes
#
# Provides:
#   aw_add_shared_library()  — SHARED library with cross-platform AW_API macros
#   aw_add_plugin_module()   — MODULE target with extern "C" factory functions
#
# Full implementation deferred to Task 03.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_shared_library()
#
# Create a SHARED library with platform-specific export macros (AW_API).
# On MSVC this uses __declspec(dllexport/dllimport); on Unix it uses
# hidden visibility.
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   HEADERS <files>...       Public header files (optional).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_shared_library TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;HEADERS;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_shared_library(${TARGET}) — stub, full impl in Task 03")
    add_library(${TARGET} SHARED ${ARG_SOURCES})
    add_library(aw::${TARGET} ALIAS ${TARGET})
    if(ARG_HEADERS)
        target_sources(${TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS include
                FILES ${ARG_HEADERS}
        )
    endif()
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
    aw_setup_install(${TARGET} ${TARGET} "aw::" include)
endfunction()

# ---------------------------------------------------------------------------
# aw_add_plugin_module()
#
# Create a MODULE library that exposes extern "C" factory functions for
# dynamic plugin loading at runtime.
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_plugin_module TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_plugin_module(${TARGET}) — stub, full impl in Task 03")
    add_library(${TARGET} MODULE ${ARG_SOURCES})
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()
