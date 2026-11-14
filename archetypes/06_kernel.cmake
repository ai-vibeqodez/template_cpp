# =============================================================================
# 06_kernel.cmake — Kernel driver archetype
#
# Provides:
#   aw_add_kernel_driver()  — Kernel-mode driver (Windows WDK .sys, Linux .ko)
#
# Full implementation deferred to Task 07.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_kernel_driver()
#
# Create a kernel-mode driver target:
#   - Windows: Builds a .sys driver using the WDK
#   - Linux:   Builds a .ko loadable kernel module using Kbuild
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   LINK_LIBRARIES <libs>    Kernel libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_kernel_driver TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_kernel_driver(${TARGET}) — stub, full impl in Task 07")
    add_library(${TARGET} MODULE ${ARG_SOURCES})
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})
endfunction()
