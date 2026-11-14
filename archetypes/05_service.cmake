# =============================================================================
# 05_service.cmake — System service and daemon executable archetype
#
# Provides:
#   aw_add_service_executable()  — Cross-platform service (Windows SCM, POSIX daemon, systemd)
#
# Full implementation deferred to Task 06.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_service_executable()
#
# Create an executable designed to run as a system service:
#   - Windows: Registers with the Service Control Manager (SCM)
#   - Linux:   Generates a systemd .service template
#   - macOS:   Creates a launchd plist template
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_service_executable TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_service_executable(${TARGET}) — stub, full impl in Task 06")
    add_executable(${TARGET} ${ARG_SOURCES})
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()
