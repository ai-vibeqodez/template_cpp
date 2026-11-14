# =============================================================================
# 01_core.cmake — Header-only and static library archetypes
#
# Provides:
#   aw_add_header_only_library()  — INTERFACE library with FILE_SET HEADERS
#   aw_add_static_library()       — STATIC library with FILE_SET HEADERS
#
# Full implementation deferred to Task 02.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_header_only_library()
#
# Create an INTERFACE library with public headers via FILE_SET HEADERS
# (CMake 3.23+).
#
# Arguments:
#   TARGET <name>          Target name (required).
#   HEADERS <files>...     Public header files (required).
#   LINK_LIBRARIES <libs>  Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_header_only_library TARGET)
    cmake_parse_arguments(ARG "" "" "HEADERS;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_header_only_library(${TARGET}) — stub, full impl in Task 02")
    add_library(${TARGET} INTERFACE)
    add_library(aw::${TARGET} ALIAS ${TARGET})
    if(ARG_HEADERS)
        target_sources(${TARGET}
            INTERFACE
                FILE_SET HEADERS
                BASE_DIRS include
                FILES ${ARG_HEADERS}
        )
    endif()
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} INTERFACE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()

# ---------------------------------------------------------------------------
# aw_add_static_library()
#
# Create a STATIC library with public headers via FILE_SET HEADERS (CMake 3.23+).
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   HEADERS <files>...       Public header files (optional).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_static_library TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;HEADERS;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_static_library(${TARGET}) — stub, full impl in Task 02")
    add_library(${TARGET} STATIC ${ARG_SOURCES})
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
