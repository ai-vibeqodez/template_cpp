# =============================================================================
# 01_core.cmake — Header-only and static library archetypes
#
# Provides:
#   aw_add_header_only_library()  — INTERFACE library with FILE_SET HEADERS
#   aw_add_static_library()       — STATIC library with FILE_SET HEADERS
#
# =============================================================================

# ---------------------------------------------------------------------------
# aw_add_header_only_library()
#
# Create an INTERFACE library with public headers via FILE_SET HEADERS
# (CMake 3.23+).  The target is exported under <namespace>::<target> where
# <namespace> is derived from AW_PROJECT_PREFIX (default "aw").
#
# Arguments:
#   TARGET <name>                Target name (required).
#   HEADERS <files>...           Public header files (required).
#   BASE_DIRS <dirs>...          Base directories for header installation.
#                                Default: "include".
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#
# Example:
#   aw_add_header_only_library(TARGET my_header_lib
#       HEADERS include/aw/my_header_lib/my_header_lib.hpp
#       BASE_DIRS include
#       LINK_LIBRARIES Threads::Threads
#   )
# ---------------------------------------------------------------------------
function(aw_add_header_only_library TARGET)
    cmake_parse_arguments(ARG
        ""
        ""
        "HEADERS;BASE_DIRS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    if(NOT ARG_HEADERS)
        message(FATAL_ERROR
            "aw_add_header_only_library(${TARGET}): "
            "HEADERS is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create INTERFACE library target
    # -------------------------------------------------------------------
    add_library(${TARGET} INTERFACE)
    add_library(aw::${TARGET} ALIAS ${TARGET})

    # -------------------------------------------------------------------
    # 2. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(NOT ARG_BASE_DIRS)
        set(ARG_BASE_DIRS "include")
    endif()

    target_sources(${TARGET}
        INTERFACE
            FILE_SET HEADERS
            BASE_DIRS ${ARG_BASE_DIRS}
            FILES ${ARG_HEADERS}
    )

    # -------------------------------------------------------------------
    # 3. Compile features & definitions
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} INTERFACE cxx_std_20)

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} INTERFACE
            ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} INTERFACE ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 4. Apply infrastructure helpers (no-op for INTERFACE when not
    #    top-level; safe to call unconditionally).
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})

    # -------------------------------------------------------------------
    # 5. Install rules
    # -------------------------------------------------------------------
    aw_setup_install(${TARGET} ${TARGET} "aw::" ${ARG_BASE_DIRS})
endfunction()

# ---------------------------------------------------------------------------
# aw_add_static_library()
#
# Create a STATIC library with public headers via FILE_SET HEADERS (CMake
# 3.23+).  The target is exported under <namespace>::<target> where
# <namespace> is derived from AW_PROJECT_PREFIX (default "aw").
#
# Static libraries are the default choice over SHARED because they avoid
# cross-platform DLL export complexity and are safer for internal use.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   BASE_DIRS <dirs>...          Base directories for header installation.
#                                Default: "include".
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#
# Example:
#   aw_add_static_library(TARGET my_lib
#       SOURCES src/my_lib.cpp
#       HEADERS include/aw/my_lib/my_lib.hpp
#       BASE_DIRS include
#       LINK_LIBRARIES Threads::Threads
#       COMPILE_DEFINITIONS MY_LIB_VERSION="1.0.0"
#   )
# ---------------------------------------------------------------------------
function(aw_add_static_library TARGET)
    cmake_parse_arguments(ARG
        ""
        ""
        "SOURCES;HEADERS;BASE_DIRS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_static_library(${TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create STATIC library target
    # -------------------------------------------------------------------
    add_library(${TARGET} STATIC ${ARG_SOURCES})
    add_library(aw::${TARGET} ALIAS ${TARGET})

    # -------------------------------------------------------------------
    # 2. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(NOT ARG_BASE_DIRS)
        set(ARG_BASE_DIRS "include")
    endif()

    if(ARG_HEADERS)
        target_sources(${TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS ${ARG_BASE_DIRS}
                FILES ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 3. Include directories (BUILD_INTERFACE / INSTALL_INTERFACE)
    # -------------------------------------------------------------------
    target_include_directories(${TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    # -------------------------------------------------------------------
    # 4. Compile features & definitions
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} PUBLIC cxx_std_20)

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 5. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})

    # -------------------------------------------------------------------
    # 6. Install rules
    # -------------------------------------------------------------------
    aw_setup_install(${TARGET} ${TARGET} "aw::" ${ARG_BASE_DIRS})
endfunction()
