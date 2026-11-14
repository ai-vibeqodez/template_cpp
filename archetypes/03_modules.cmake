# =============================================================================
# 03_modules.cmake — C++20 module library archetype
#
# Provides:
#   aw_add_cxx_module_library()  — Library built with C++20 modules (CMake 3.28+)
#
# Full implementation deferred to Task 04.
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_cxx_module_library()
#
# Create a library using C++20 modules via CMake 3.28+ FILE_SET CXX_MODULES.
# Falls back to traditional headers if the CMake version is too old.
#
# Arguments:
#   TARGET <name>            Target name (required).
#   SOURCES <files>...       Source files (required).
#   MODULES <files>...       C++20 module interface units (optional).
#   HEADERS <files>...       Public header files (optional).
#   LINK_LIBRARIES <libs>    Libraries to link against (optional).
# ---------------------------------------------------------------------------
function(aw_add_cxx_module_library TARGET)
    cmake_parse_arguments(ARG "" "" "SOURCES;MODULES;HEADERS;LINK_LIBRARIES" ${ARGN})
    message(STATUS "[archetype] aw_add_cxx_module_library(${TARGET}) — stub, full impl in Task 04")
    if(CMAKE_VERSION VERSION_LESS "3.28")
        message(WARNING "aw_add_cxx_module_library(${TARGET}): "
                       "CMake ${CMAKE_VERSION} < 3.28; modules not supported, "
                       "falling back to regular library")
        add_library(${TARGET} STATIC ${ARG_SOURCES})
    else()
        add_library(${TARGET} STATIC ${ARG_SOURCES})
        if(ARG_MODULES)
            target_sources(${TARGET}
                PUBLIC
                    FILE_SET CXX_MODULES
                    FILES ${ARG_MODULES}
            )
        endif()
    endif()
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
