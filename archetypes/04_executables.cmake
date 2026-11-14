# =============================================================================
# 04_executables.cmake — Executable and GUI application archetypes
#
# Provides:
#   aw_add_executable()          — Standard CLI executable
#   aw_add_gui_executable()      — GUI executable (Win32 subsystem, macOS .app, Linux binary)
#
# Full implementation deferred to Task 05.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_executable()
#
# Create a standard CLI executable.
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_executable TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_executable(${TARGET}) — stub, full impl in Task 05")
    add_executable(${TARGET} ${ARG_SOURCES})
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()

# ---------------------------------------------------------------------------
# aw_add_gui_executable()
#
# Create a GUI executable with platform-specific configuration:
#   - Windows: WIN32 subsystem (no console window)
#   - macOS:   MACOSX_BUNDLE (produces a .app bundle)
#   - Linux:   standard binary (no special handling)
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_gui_executable TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_gui_executable(${TARGET}) — stub, full impl in Task 05")
    if(WIN32)
        add_executable(${TARGET} WIN32 ${ARG_SOURCES})
    elseif(APPLE)
        add_executable(${TARGET} MACOSX_BUNDLE ${ARG_SOURCES})
    else()
        add_executable(${TARGET} ${ARG_SOURCES})
    endif()
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()
