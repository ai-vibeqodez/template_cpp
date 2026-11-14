# =============================================================================
# 03_modules.cmake — C++20 module library archetype
#
# Provides:
#   aw_add_cxx_module_library()  — C++20 module library using FILE_SET
#                                  CXX_MODULES (CMake 3.28+) with fallback
#                                  to a traditional STATIC library for older
#                                  CMake versions.
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.
set(_aw_modules_dir "${CMAKE_CURRENT_LIST_DIR}")

# ---------------------------------------------------------------------------
# aw_add_cxx_module_library()
#
# Create a C++20 module library target.  On CMake 3.28+ the module source
# files (.cppm) and interface headers (.hin) are registered via
# FILE_SET CXX_MODULES / FILE_SET HEADERS.  On older CMake versions a
# STATIC library is produced as a fallback (module sources are compiled as
# regular .cpp units).
#
# Arguments:
#   TARGET <name>                Target name (required).
#   MODULES <files>...           C++20 module implementation units (.cppm)
#                                (required when CMake >= 3.28).
#   HEADERS <files>...           C++20 module interface headers (.hin) or
#                                regular public headers (optional).
#   BASE_DIRS <dirs>...          Base directories for header installation.
#                                Default: "include".
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   MODULE_NAME <name>           Logical module name for `export module` /
#                                `import`. Default: derived from TARGET.
#
# Example:
#   aw_add_cxx_module_library(TARGET my_module
#       MODULES src/my_module.cppm
#       HEADERS include/aw/my_module/my_module.hin
#       BASE_DIRS include
#       LINK_LIBRARIES Threads::Threads
#       MODULE_NAME my_module
#   )
# ---------------------------------------------------------------------------
function(aw_add_cxx_module_library)
    cmake_parse_arguments(ARG
        "MODULE_NAME"
        ""
        "TARGET;MODULES;HEADERS;BASE_DIRS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_cxx_module_library(): "
            "TARGET is required")
    endif()

    if(NOT ARG_MODULES)
        message(FATAL_ERROR
            "aw_add_cxx_module_library(${ARG_TARGET}): "
            "MODULES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive MODULE_NAME from TARGET if not supplied
    # -------------------------------------------------------------------
    if(NOT ARG_MODULE_NAME)
        string(REPLACE "-" "_" ARG_MODULE_NAME "${ARG_TARGET}")
    endif()

    # -------------------------------------------------------------------
    # 2. CMake version check — CXX_MODULES FILE_SET requires 3.28+
    # -------------------------------------------------------------------
    if(CMAKE_VERSION VERSION_LESS "3.28")
        message(WARNING
            "aw_add_cxx_module_library(${ARG_TARGET}): "
            "C++20 modules require CMake 3.28+ (found ${CMAKE_VERSION}); "
            "falling back to traditional header-based STATIC library build")

        # --- Fallback: compile .cppm files as regular .cpp units ----------
        add_library(${ARG_TARGET} STATIC ${ARG_MODULES})

        # Rename .cppm sources to .cpp for compilation
        set(_aw_fallback_sources "")
        foreach(_aw_src IN LISTS ARG_MODULES)
            get_filename_component(_aw_base "${_aw_src}" NAME_WE)
            set(_aw_out "${CMAKE_CURRENT_BINARY_DIR}/${_aw_base}.cpp")
            # Copy the .cppm file; the compiler will treat it as a regular
            # translation unit when module support is absent.
            configure_file("${_aw_src}" "${_aw_out}" COPYONLY)
            list(APPEND _aw_fallback_sources "${_aw_out}")
        endforeach()
        set_source_files_properties(${_aw_fallback_sources} PROPERTIES
            HEADER_FILE_ONLY OFF)

        if(ARG_HEADERS)
            target_sources(${ARG_TARGET}
                PUBLIC
                    FILE_SET HEADERS
                    FILES ${ARG_HEADERS}
            )
        endif()

        target_include_directories(${ARG_TARGET}
            PUBLIC
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
        )

        target_compile_features(${ARG_TARGET} PUBLIC cxx_std_20)

        if(ARG_COMPILE_DEFINITIONS)
            target_compile_definitions(${ARG_TARGET} PUBLIC
                ${ARG_COMPILE_DEFINITIONS})
        endif()

        if(ARG_LINK_LIBRARIES)
            target_link_libraries(${ARG_TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
        endif()

        _aw_set_warnings(${ARG_TARGET})
        _aw_apply_sanitizers(${ARG_TARGET})
        _aw_apply_coverage(${ARG_TARGET})
        aw_add_lint(${ARG_TARGET})

        aw_setup_install(${ARG_TARGET} ${ARG_TARGET} "aw::" "include")

        add_library(aw::${ARG_TARGET} ALIAS ${ARG_TARGET})
        return()
    endif()

    # -------------------------------------------------------------------
    # 3. Create STATIC library target (CMake does not support MODULE for
    #    C++20 modules — they are compiled into a static library).
    # -------------------------------------------------------------------
    add_library(${ARG_TARGET} STATIC ${ARG_MODULES})
    add_library(aw::${ARG_TARGET} ALIAS ${ARG_TARGET})

    # -------------------------------------------------------------------
    # 4. FILE_SET CXX_MODULES (CMake 3.28+)
    # -------------------------------------------------------------------
    target_sources(${ARG_TARGET}
        PUBLIC
            FILE_SET CXX_MODULES
            BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}
            FILES ${ARG_MODULES}
    )

    # -------------------------------------------------------------------
    # 5. FILE_SET HEADERS for interface headers
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
    # 6. Include directories
    # -------------------------------------------------------------------
    target_include_directories(${ARG_TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    # -------------------------------------------------------------------
    # 7. Compile features & definitions
    # -------------------------------------------------------------------
    target_compile_features(${ARG_TARGET} PUBLIC cxx_std_20)

    # Define a feature macro for compile-time detection (e.g. #ifdef
    # MY_MODULE_ENABLED).
    target_compile_definitions(${ARG_TARGET} PRIVATE
        "${ARG_MODULE_NAME}_ENABLED=1")

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${ARG_TARGET} PUBLIC
            ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${ARG_TARGET} PUBLIC ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 8. Compiler-specific module flags
    # -------------------------------------------------------------------
    if(MSVC)
        # MSVC module support is still experimental.
        # /experimental:module enables the C++20 Modules TS.
        # /std:c++latest may be needed for newer features.
        target_compile_options(${ARG_TARGET} PRIVATE
            /experimental:module
            /std:c++latest
            /ifcOutput "${CMAKE_CURRENT_BINARY_DIR}/ifcs")
        # Export the IFD/IFC output directory so incremental builds work.
        set_target_properties(${ARG_TARGET} PROPERTIES
            CXX_MODULES_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/ifcs")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        # GCC module support is experimental; -fmodules is the flag.
        target_compile_options(${ARG_TARGET} PRIVATE -fmodules)
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        # Clang uses the C++ Modules TS flag.
        target_compile_options(${ARG_TARGET} PRIVATE -fmodules-ts)
    endif()

    # -------------------------------------------------------------------
    # 9. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${ARG_TARGET})
    _aw_apply_sanitizers(${ARG_TARGET})
    _aw_apply_coverage(${ARG_TARGET})
    aw_add_lint(${ARG_TARGET})

    # -------------------------------------------------------------------
    # 10. Install rules
    # -------------------------------------------------------------------
    aw_setup_install(${ARG_TARGET} ${ARG_TARGET} "aw::" ${ARG_BASE_DIRS})
endfunction()
