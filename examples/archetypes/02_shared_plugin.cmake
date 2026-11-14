# =============================================================================
# 02_shared_plugin.cmake — Shared library and plugin module archetypes
#
# Provides:
#   aw_add_shared_library()  — SHARED library with cross-platform AW_API macros
#   aw_add_plugin_module()   — MODULE target with extern "C" factory functions
#
# =============================================================================

# Capture the directory where this .cmake file lives; CMAKE_CURRENT_LIST_DIR
# resolves to the calling context inside functions, so we store it here.
set(_aw_shared_plugin_dir "${CMAKE_CURRENT_LIST_DIR}")

# ---------------------------------------------------------------------------
# aw_add_shared_library()
#
# Create a SHARED library with platform-specific export macros (AW_API).
# On MSVC this uses __declspec(dllexport/dllimport); on Unix it uses
# hidden visibility with __attribute__((visibility("default"))).
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   BASE_DIRS <dirs>...          Base directories for header installation.
#                                Default: "include".
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   EXPORT_MACRO <macro>         Export macro name. Default: AW_API.
#   EXPORT_MACRO_DEFINE <define> Define for building the library.
#                                Default: <TARGET>_BUILDING.
#
# Example:
#   aw_add_shared_library(TARGET my_lib
#       SOURCES src/my_lib.cpp
#       HEADERS include/aw/my_lib/my_lib.hpp
#       BASE_DIRS include
#       LINK_LIBRARIES Threads::Threads
#       COMPILE_DEFINITIONS MY_LIB_VERSION="1.0.0"
#   )
# ---------------------------------------------------------------------------
function(aw_add_shared_library)
    cmake_parse_arguments(ARG
        "EXPORT_MACRO;EXPORT_MACRO_DEFINE"
        ""
        "TARGET;SOURCES;HEADERS;BASE_DIRS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_shared_library(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_shared_library(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create SHARED library target
    # -------------------------------------------------------------------
    add_library(${ARG_TARGET} SHARED ${ARG_SOURCES})
    add_library(aw::${ARG_TARGET} ALIAS ${ARG_TARGET})

    # -------------------------------------------------------------------
    # 2. Export macro define (e.g. MY_LIB_BUILDING)
    # -------------------------------------------------------------------
    if(NOT ARG_EXPORT_MACRO)
        set(ARG_EXPORT_MACRO "AW_API")
    endif()
    if(NOT ARG_EXPORT_MACRO_DEFINE)
        set(ARG_EXPORT_MACRO_DEFINE "${ARG_TARGET}_BUILDING")
    endif()

    target_compile_definitions(${ARG_TARGET} PRIVATE ${ARG_EXPORT_MACRO_DEFINE})

    # -------------------------------------------------------------------
    # 3. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(NOT ARG_BASE_DIRS)
        set(ARG_BASE_DIRS "include")
    endif()

    if(ARG_HEADERS)
        target_sources(${ARG_TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS ${ARG_BASE_DIRS}
                FILES ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 4. Include directories (BUILD_INTERFACE / INSTALL_INTERFACE)
    # -------------------------------------------------------------------
    target_include_directories(${ARG_TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    # -------------------------------------------------------------------
    # 5. Compile features & definitions
    # -------------------------------------------------------------------
    target_compile_features(${ARG_TARGET} PUBLIC cxx_std_20)

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${ARG_TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${ARG_TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 6. Platform-specific entry point / init skeleton
    # -------------------------------------------------------------------
    if(WIN32)
        # Include DllMain.cpp skeleton on Windows.
        set(_aw_dllmain_file "${_aw_shared_plugin_dir}/skeletons/shared/DllMain.cpp.in")
        if(EXISTS "${_aw_dllmain_file}")
            configure_file(
                "${_aw_dllmain_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_DllMain.cpp"
                COPYONLY
            )
            target_sources(${ARG_TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_DllMain.cpp")
        endif()
    else()
        # Include init.cpp skeleton with constructor/destructor on POSIX.
        set(_aw_init_file "${_aw_shared_plugin_dir}/skeletons/shared/init.cpp.in")
        if(EXISTS "${_aw_init_file}")
            configure_file(
                "${_aw_init_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_init.cpp"
                COPYONLY
            )
            target_sources(${ARG_TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_init.cpp")
        endif()
    endif()

    # -------------------------------------------------------------------
    # 7. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${ARG_TARGET})
    _aw_apply_sanitizers(${ARG_TARGET})
    _aw_apply_coverage(${ARG_TARGET})
    aw_add_lint(${ARG_TARGET})

    # -------------------------------------------------------------------
    # 8. Install rules
    # -------------------------------------------------------------------
    aw_setup_install(${ARG_TARGET} ${ARG_TARGET} "aw::" ${ARG_BASE_DIRS})
endfunction()

# ---------------------------------------------------------------------------
# aw_add_plugin_module()
#
# Create a MODULE library that exposes extern "C" factory functions for
# dynamic plugin loading at runtime.  Plugin modules are not linked into
# the final executable; they are loaded via dlopen()/LoadLibrary().
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   BASE_DIRS <dirs>...          Base directories for header installation.
#                                Default: "include".
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   FACTORY_NAME <function>      Factory function name. Default: create_plugin.
#
# Example:
#   aw_add_plugin_module(TARGET my_plugin
#       SOURCES src/my_plugin.cpp
#       HEADERS include/aw/my_plugin/plugin_interface.hpp
#       BASE_DIRS include
#       LINK_LIBRARIES aw::my_shared_lib
#       FACTORY_NAME create_my_plugin
#   )
#
# NOTE: Plugins are NOT installed to system paths (no aw_setup_install).
#       Plugins are deployed alongside the host application.
#       No ALIAS target is created (no library consumer interface).
# ---------------------------------------------------------------------------
function(aw_add_plugin_module)
    cmake_parse_arguments(ARG
        "FACTORY_NAME"
        ""
        "TARGET;SOURCES;HEADERS;BASE_DIRS;LINK_LIBRARIES"
        ${ARGN}
    )

    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_plugin_module(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_plugin_module(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create MODULE library target
    # -------------------------------------------------------------------
    add_library(${ARG_TARGET} MODULE ${ARG_SOURCES})

    # On macOS, MODULE libraries default to .so suffix; set proper suffix.
    set_target_properties(${ARG_TARGET} PROPERTIES
        BUILD_WITH_INSTALL_RPATH ON
        INSTALL_RPATH_USE_LINK_PATH ON
    )

    # -------------------------------------------------------------------
    # 2. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(NOT ARG_BASE_DIRS)
        set(ARG_BASE_DIRS "include")
    endif()

    if(ARG_HEADERS)
        target_sources(${ARG_TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS ${ARG_BASE_DIRS}
                FILES ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 3. Include directories
    # -------------------------------------------------------------------
    target_include_directories(${ARG_TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    # -------------------------------------------------------------------
    # 4. Compile features
    # -------------------------------------------------------------------
    target_compile_features(${ARG_TARGET} PUBLIC cxx_std_20)

    # -------------------------------------------------------------------
    # 5. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${ARG_TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 6. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${ARG_TARGET})
    _aw_apply_sanitizers(${ARG_TARGET})
    _aw_apply_coverage(${ARG_TARGET})
    aw_add_lint(${ARG_TARGET})

    # NOTE: No aw_setup_install() — plugins are deployed alongside the host.
    # NOTE: No ALIAS target — plugins have no library consumer interface.
endfunction()
