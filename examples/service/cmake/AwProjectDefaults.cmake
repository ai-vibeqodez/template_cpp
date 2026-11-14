# =============================================================================
# AwProjectDefaults.cmake — Reusable CMake infrastructure for ai-warevo C++20
# projects.  Source-of-truth for the `template-cpp` repository.
#
# When consumed via FetchContent:
#   - Tests, examples and lint targets are automatically disabled.
#   - Only the library target, its compile features and install rules are
#     available to the consumer.
#
# When used as a top-level project:
#   - All targets (tests, examples, lint) are enabled.
#   - CMAKE_EXPORT_COMPILE_COMMANDS is set for clangd / clang-tidy.
#
# CMake options (set before the first configure):
#   AW_<PROJECT>_WARNINGS_AS_ERRORS  Build with -Wall -Wextra … -Werror  (OFF)
#   AW_<PROJECT>_BUILD_EXAMPLES      Build examples/ subdirectory         (ON if top-level)
#   AW_<PROJECT>_BUILD_TESTS         Build tests/ subdirectory             (ON if top-level)
#   AW_<PROJECT>_ENABLE_COVERAGE     Enable gcov / lcov instrumentation    (OFF)
#   AW_<PROJECT>_SANITIZE            Sanitizer: none | address | thread    (none)
#   AW_<PROJECT>_INSTALL             Generate install rules                (ON if top-level)
# =============================================================================

# ---------------------------------------------------------------------------
# Guard: do not re-apply when consumed as a dependency
# ---------------------------------------------------------------------------
if(TARGET aw::core_defaults)
    return()
endif()

# ---------------------------------------------------------------------------
# Project-level variable prefix — each downstream project sets this:
#   set(AW_PROJECT_PREFIX "TPL")  →  AW_TPL_…
# Falls back to PROJECT_NAME uppercased when not set.
# ---------------------------------------------------------------------------
if(NOT DEFINED AW_PROJECT_PREFIX)
    string(TOUPPER "${PROJECT_NAME}" AW_PROJECT_PREFIX)
endif()
string(TOLOWER "${AW_PROJECT_PREFIX}" _aw_prefix_lower)

# ---------------------------------------------------------------------------
# Top-level detection
# ---------------------------------------------------------------------------
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL ON)
else()
    set(AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL OFF)
endif()

if(AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# ---------------------------------------------------------------------------
# C++20 / C++23 standard enforcement
# ---------------------------------------------------------------------------
set(AW_${AW_PROJECT_PREFIX}_CXX_STANDARD 20 CACHE STRING
    "C++ standard version (20 or 23)")
set_property(CACHE AW_${AW_PROJECT_PREFIX}_CXX_STANDARD PROPERTY STRINGS 20 23)

# Apply the standard globally so every target compiled in this project
# picks up the correct /std:c++XX flag on MSVC (which requires the
# explicit compiler flag; compile_features alone is sometimes ignored).
set(CMAKE_CXX_STANDARD "${AW_${AW_PROJECT_PREFIX}_CXX_STANDARD}")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# Warnings-as-errors (off by default; CI / developers turn it on)
# ---------------------------------------------------------------------------
option(AW_${AW_PROJECT_PREFIX}_WARNINGS_AS_ERRORS
       "Build with strict warnings treated as errors" OFF)

function(_aw_set_warnings TARGET)
    if(AW_${AW_PROJECT_PREFIX}_WARNINGS_AS_ERRORS)
        if(MSVC)
            target_compile_options(${TARGET} PRIVATE /W4 /WX)
        else()
            target_compile_options(${TARGET} PRIVATE
                -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Werror)
        endif()
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Sanitizers
# ---------------------------------------------------------------------------
set(AW_${AW_PROJECT_PREFIX}_SANITIZE "none" CACHE STRING
    "Sanitizer to enable: none, address (ASan+UBSan) or thread (TSan)")
set_property(CACHE AW_${AW_PROJECT_PREFIX}_SANITIZE PROPERTY
             STRINGS none address thread)

function(_aw_apply_sanitizers TARGET)
    if(NOT AW_${AW_PROJECT_PREFIX}_SANITIZE STREQUAL "none")
        if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
            message(FATAL_ERROR
                "AW_${AW_PROJECT_PREFIX}_SANITIZE requires GCC or Clang")
        endif()
        if(AW_${AW_PROJECT_PREFIX}_ENABLE_COVERAGE)
            message(FATAL_ERROR
                "AW_${AW_PROJECT_PREFIX}_SANITIZE cannot be combined with "
                "AW_${AW_PROJECT_PREFIX}_ENABLE_COVERAGE")
        endif()
        if(AW_${AW_PROJECT_PREFIX}_SANITIZE STREQUAL "address")
            set(_aw_san_flags "address,undefined")
        elseif(AW_${AW_PROJECT_PREFIX}_SANITIZE STREQUAL "thread")
            set(_aw_san_flags "thread")
        else()
            message(FATAL_ERROR
                "AW_${AW_PROJECT_PREFIX}_SANITIZE must be one of: none, address, thread")
        endif()
        target_compile_options(${TARGET} PUBLIC
            -fsanitize=${_aw_san_flags} -fno-omit-frame-pointer -g)
        target_link_options(${TARGET} PUBLIC
            -fsanitize=${_aw_san_flags})
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Code coverage
# ---------------------------------------------------------------------------
option(AW_${AW_PROJECT_PREFIX}_ENABLE_COVERAGE
       "Enable code coverage instrumentation" OFF)

function(_aw_apply_coverage TARGET)
    if(AW_${AW_PROJECT_PREFIX}_ENABLE_COVERAGE
       AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${TARGET} PUBLIC
            --coverage -O0 -g -fprofile-update=atomic)
        target_link_options(${TARGET} PUBLIC --coverage)
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Install & package export helpers
# ---------------------------------------------------------------------------
option(AW_${AW_PROJECT_PREFIX}_INSTALL
       "Generate install rules and package config" ${AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL})

# Public: aw_setup_install()
#
# Configure install rules for a target.  Exports targets, writes a package
# config file, and installs headers via FILE_SET HEADERS (CMake 3.23+).
#
# @param TARGET        Target name to install.
# @param EXPORT_NAME   Export set name (used for generated *.cmake files).
# @param NAMESPACE     Imported target namespace prefix (e.g. "aw::").
# @param INCLUDE_DIR   Path to the public header directory.
function(aw_setup_install TARGET EXPORT_NAME NAMESPACE INCLUDE_DIR)
    if(NOT AW_${AW_PROJECT_PREFIX}_INSTALL)
        return()
    endif()
    include(GNUInstallDirs)
    include(CMakePackageConfigHelpers)

    install(TARGETS ${TARGET}
        EXPORT ${EXPORT_NAME}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        FILE_SET HEADERS DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

    install(EXPORT ${EXPORT_NAME}
        FILE ${EXPORT_NAME}Targets.cmake
        NAMESPACE ${NAMESPACE}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${EXPORT_NAME}
    )

    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}Config.cmake"
        "include(CMakeFindDependencyMacro)\n"
        "include(\"\\\${CMAKE_CURRENT_LIST_DIR}/${EXPORT_NAME}Targets.cmake\")\n"
    )

    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}ConfigVersion.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${EXPORT_NAME}
    )
endfunction()

# ---------------------------------------------------------------------------
# Test discovery (Catch2) — only when top-level
# ---------------------------------------------------------------------------

# Public: aw_setup_tests()
#
# Register tests with CTest using Catch2 test discovery.  A no-op when the
# project is consumed as a dependency (not top-level).
#
# @param TEST_EXECUTABLE  Name of the test executable target.
function(aw_setup_tests TEST_EXECUTABLE)
    if(NOT AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL)
        return()
    endif()
    include(CTest)
    if(WIN32)
        add_test(NAME aw_tests COMMAND ${TEST_EXECUTABLE})
        set_tests_properties(aw_tests PROPERTIES TIMEOUT 300)
    else()
        include(Catch)
        catch_discover_tests(${TEST_EXECUTABLE} PROPERTIES TIMEOUT 120)
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Lint helper (clang-tidy) — top-level only
# ---------------------------------------------------------------------------

# Public: aw_add_lint()
#
# Attach clang-tidy to a target when the program is available and the project
# is top-level.  A no-op otherwise.
#
# @param TARGET  Name of the target to lint.
function(aw_add_lint TARGET)
    if(NOT AW_${AW_PROJECT_PREFIX}_IS_TOP_LEVEL)
        return()
    endif()
    find_program(_AW_CLANG_TIDY clang-tidy)
    if(_AW_CLANG_TIDY)
        set_target_properties(${TARGET} PROPERTIES
            CXX_CLANG_TIDY "${_AW_CLANG_TIDY}")
    endif()
    unset(_AW_CLANG_TIDY CACHE)
endfunction()


# ---------------------------------------------------------------------------
# Mark infrastructure target as consumed
# ---------------------------------------------------------------------------
add_library(aw::core_defaults INTERFACE IMPORTED)
set_target_properties(aw::core_defaults PROPERTIES
    INTERFACE_COMPILE_FEATURES cxx_std_20)
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
    #
    # Only the public header base directory is exposed — never the project
    # root, because a stray file named “version” (lowercase) in the root
    # would shadow the C++20 <version> header when #include "version" is
    # resolved (quoted lookup scans BUILD_INTERFACE dirs first).
    # FILE_SET HEADERS already registers the include/ tree; we only need
    # the base directory itself so that #include <aw/…> resolves.
    # -------------------------------------------------------------------
    target_include_directories(${TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${ARG_BASE_DIRS}>
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
# =============================================================================
# 04_executables.cmake — Executable and GUI application archetypes
#
# Provides:
#   aw_add_executable()          — Standard CLI executable with argument
#                                  parsing skeleton support.
#   aw_add_gui_executable()      — GUI executable with platform-specific
#                                  configuration (Win32 subsystem, macOS
#                                  .app bundle, Linux binary + desktop).
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.

# ===========================================================================
# aw_add_executable()
#
# Create a standard CLI executable target.  The resulting binary runs as a
# console application on all platforms.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_executable(TARGET my_cli
#       SOURCES src/my_cli.cpp
#       LINK_LIBRARIES aw::my_lib
#       COMPILE_DEFINITIONS MY_CLI_VERSION="1.0.0"
#   )
# ===========================================================================
function(aw_add_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "INSTALL_DESTINATION"
        "SOURCES;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_executable(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create EXECUTABLE target (console subsystem on all platforms)
    # -------------------------------------------------------------------
    add_executable(${TARGET} ${ARG_SOURCES})

    # No ALIAS target — executables are not imported by other projects.

    # -------------------------------------------------------------------
    # 2. Compile features
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} PUBLIC cxx_std_20)

    # -------------------------------------------------------------------
    # 3. Compile definitions
    # -------------------------------------------------------------------
    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 4. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
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
    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    include(GNUInstallDirs)
    install(TARGETS ${TARGET}
        RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
    )
endfunction()

# ===========================================================================
# aw_add_gui_executable()
#
# Create a GUI executable with platform-specific configuration:
#   - Windows: WIN32 subsystem (no console window, GUI entry point).
#   - macOS:   MACOSX_BUNDLE (.app bundle with Info.plist).
#   - Linux:   Standard binary; installs .desktop file and icon.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   RESOURCES <files>...         Platform-specific resource files (e.g. .rc)
#                                (optional).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   APP_NAME <name>              Human-readable application name.
#                                Default: derived from TARGET.
#   APP_ICON <icon_file>         Platform-specific icon file (optional).
#   BUNDLE_ID <id>               macOS bundle identifier (reverse-DNS).
#                                Default: com.aw.<APP_NAME>.
#   APP_VERSION <version>        Application version string.
#                                Default: ${PROJECT_VERSION}.
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_gui_executable(TARGET my_gui
#       SOURCES src/my_gui.cpp
#       RESOURCES src/icon.rc
#       APP_NAME "My GUI App"
#       APP_VERSION "1.0.0"
#       LINK_LIBRARIES aw::my_lib
#   )
# ===========================================================================
function(aw_add_gui_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "TARGET;INSTALL_DESTINATION;APP_NAME;APP_ICON;BUNDLE_ID;APP_VERSION"
        "SOURCES;HEADERS;RESOURCES;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_gui_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_gui_executable(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_APP_NAME)
        set(ARG_APP_NAME "${ARG_TARGET}")
    endif()

    if(NOT ARG_APP_VERSION)
        set(ARG_APP_VERSION "${PROJECT_VERSION}")
    endif()

    if(NOT ARG_BUNDLE_ID)
        set(ARG_BUNDLE_ID "com.aw.${ARG_APP_NAME}")
    endif()

    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    # -------------------------------------------------------------------
    # 2. Create target based on platform
    # -------------------------------------------------------------------
    if(WIN32)
        # Windows: WIN32 flag → GUI subsystem (no console window).
        add_executable(${ARG_TARGET} WIN32 ${ARG_SOURCES})

        # Include Win32 resource files if provided.
        if(ARG_RESOURCES)
            target_sources(${ARG_TARGET} PRIVATE ${ARG_RESOURCES})
        endif()

        # Include Win32 skeleton resource header if the user hasn't
        # provided their own.
        set(_aw_win_res_header "${ARG_TARGET}_resource.h")
        set(_aw_win_res_file "${_aw_executables_dir}/skeletons/gui/win32/resource.h.in")
        if(EXISTS "${_aw_win_res_file}")
            configure_file("${_aw_win_res_file}" "${CMAKE_CURRENT_BINARY_DIR}/${_aw_win_res_header}" COPYONLY)
            target_include_directories(${ARG_TARGET} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
        endif()

        # Generate the resource script from the skeleton if the user did
        # not supply one explicitly.
        if(NOT ARG_RESOURCES)
            set(_aw_win_rc_file "${_aw_executables_dir}/skeletons/gui/win32/icon.rc.in")
            if(EXISTS "${_aw_win_rc_file}")
                configure_file(
                    "${_aw_win_rc_file}"
                    "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_icon.rc"
                    @ONLY
                )
                target_sources(${ARG_TARGET} PRIVATE
                    "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_icon.rc")
            endif()
        endif()

    elseif(APPLE)
        # macOS: MACOSX_BUNDLE → .app bundle.
        add_executable(${ARG_TARGET} MACOSX_BUNDLE ${ARG_SOURCES})

        # Generate Info.plist from the skeleton.
        set(_aw_plist_file "${_aw_executables_dir}/skeletons/gui/macos/Info.plist.in")
        if(EXISTS "${_aw_plist_file}")
            configure_file(
                "${_aw_plist_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app/Contents/Info.plist"
                @ONLY
            )
            # Place the generated plist inside the bundle structure.
            set(_aw_plist_dest "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app/Contents/Info.plist")
            if(EXISTS "${_aw_plist_dest}")
                set_target_properties(${ARG_TARGET} PROPERTIES
                    MACOSX_BUNDLE_INFO_PLIST "${_aw_plist_dest}")
            endif()
        endif()

        # Include the Swift AppDelegate if the user hasn't provided
        # their own sources.
        set(_aw_swift_file "${_aw_executables_dir}/skeletons/gui/macos/AppDelegate.swift.in")
        if(EXISTS "${_aw_swift_file}")
            configure_file(
                "${_aw_swift_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_AppDelegate.swift"
                COPYONLY
            )
            target_sources(${ARG_TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_AppDelegate.swift")
        endif()

    else()
        # Linux: standard executable, no subsystem flag.
        add_executable(${ARG_TARGET} ${ARG_SOURCES})

        # Install .desktop file and icon for desktop integration.
        set(_aw_desktop_file "${_aw_executables_dir}/skeletons/gui/linux/app.desktop.in")
        if(EXISTS "${_aw_desktop_file}")
            configure_file(
                "${_aw_desktop_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.desktop"
                @ONLY
            )
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.desktop"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications/"
            )
        endif()

        set(_aw_icon_file "${_aw_executables_dir}/skeletons/gui/linux/icons/symbolic.svg.in")
        if(EXISTS "${_aw_icon_file}")
            configure_file(
                "${_aw_icon_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}-symbolic.svg"
                @ONLY
            )
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}-symbolic.svg"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps/"
            )
        endif()
    endif()

    # No ALIAS target — executables are not imported by other projects.

    # -------------------------------------------------------------------
    # 3. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(ARG_HEADERS)
        target_sources(${ARG_TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}
                FILES ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 4. Include directories
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

    # Platform-specific compile definitions.
    if(WIN32)
        target_compile_definitions(${ARG_TARGET} PRIVATE WIN32_LEAN_AND_MEAN)
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${ARG_TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 6. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${ARG_TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
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
    include(GNUInstallDirs)

    if(APPLE)
        # macOS: install .app bundle to /Applications.
        install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app"
            DESTINATION "Applications"
            COMPONENT Applications
        )
    else()
        # Windows / Linux: install binary to bindir.
        install(TARGETS ${ARG_TARGET}
            RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
        )
    endif()
endfunction()
# =============================================================================
# 05_service.cmake — System service and daemon executable archetype
#
# Provides:
#   aw_add_service_executable()  — Cross-platform service (Windows SCM,
#                                  POSIX daemon, systemd .service unit)
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.

# ===========================================================================
# aw_add_service_executable()
#
# Create an executable designed to run as a system service:
#   - Windows: Registers with the Service Control Manager (SCM)
#              as a WIN32 service with ServiceMain + ControlHandler.
#   - Linux:   Generates a systemd .service unit file with security
#              hardening (NoNewPrivileges, ProtectSystem, etc.).
#   - macOS:   Generates a POSIX daemon with fork/setsid and SIGTERM/SIGINT
#              handling.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   SERVICE_NAME <name>          Service name used by SCM/systemd.
#                                Default: derived from TARGET (underscores
#                                replaced with hyphens).
#   SERVICE_DISPLAY_NAME <name>  Human-readable display name.
#                                Default: same as SERVICE_NAME.
#   SERVICE_DESCRIPTION <desc>   Short description of the service.
#                                Default: "An aw::service application".
#   SERVICE_USER <user>          Unix user to run the daemon as.
#                                Default: "root".
#   SERVICE_GROUP <group>        Unix group for the daemon.
#                                Default: "root".
#   PLATFORM <windows|posix|auto>
#                                Force target platform.
#                                Default: auto (detect from CMAKE_SYSTEM_NAME).
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_service_executable(TARGET my_service
#       SOURCES src/my_service.cpp
#       LINK_LIBRARIES aw::my_lib
#       SERVICE_NAME "my-service"
#       SERVICE_USER "myapp"
#       SERVICE_GROUP "myapp"
#   )
# ===========================================================================
function(aw_add_service_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "SERVICE_NAME;SERVICE_DISPLAY_NAME;SERVICE_DESCRIPTION;SERVICE_USER;SERVICE_GROUP;PLATFORM;INSTALL_DESTINATION"
        "SOURCES;HEADERS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT TARGET)
        message(FATAL_ERROR
            "aw_add_service_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_service_executable(${TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_SERVICE_NAME)
        set(ARG_SERVICE_NAME "${TARGET}")
        string(REPLACE "_" "-" ARG_SERVICE_NAME "${ARG_SERVICE_NAME}")
    endif()

    if(NOT ARG_SERVICE_DISPLAY_NAME)
        set(ARG_SERVICE_DISPLAY_NAME "${ARG_SERVICE_NAME}")
    endif()

    if(NOT ARG_SERVICE_DESCRIPTION)
        set(ARG_SERVICE_DESCRIPTION "An aw::service application")
    endif()

    if(NOT ARG_SERVICE_USER)
        set(ARG_SERVICE_USER "root")
    endif()

    if(NOT ARG_SERVICE_GROUP)
        set(ARG_SERVICE_GROUP "root")
    endif()

    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    # -------------------------------------------------------------------
    # 2. Detect platform
    # -------------------------------------------------------------------
    if(ARG_PLATFORM)
        if(ARG_PLATFORM STREQUAL "windows")
            set(_aw_platform "windows")
        elseif(ARG_PLATFORM STREQUAL "posix")
            set(_aw_platform "posix")
        else()
            message(FATAL_ERROR
                "aw_add_service_executable(${TARGET}): "
                "PLATFORM must be 'windows', 'posix', or 'auto'")
        endif()
    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        set(_aw_platform "windows")
    else()
        set(_aw_platform "posix")
    endif()

    # -------------------------------------------------------------------
    # 3. Create target
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # Windows: WIN32 flag → GUI subsystem (no console window).
        add_executable(${TARGET} WIN32 ${ARG_SOURCES})
    else()
        # POSIX: standard executable.
        add_executable(${TARGET} ${ARG_SOURCES})
    endif()

    # No ALIAS target — services are not imported by other projects.

    # -------------------------------------------------------------------
    # 4. Compile features
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} PUBLIC cxx_std_20)

    # -------------------------------------------------------------------
    # 5. Platform-specific compile definitions
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        target_compile_definitions(${TARGET} PRIVATE
            WIN32_LEAN_AND_MEAN
            _UNICODE
            UNICODE
        )
    else()
        target_compile_definitions(${TARGET} PRIVATE
            AW_SERVICE_POSIX
        )
    endif()

    # -------------------------------------------------------------------
    # 6. User-provided compile definitions
    # -------------------------------------------------------------------
    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 7. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 8. Add skeleton sources and installable artifacts
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # --- Windows service source ---
        set(_aw_svc_header "${_aw_service_dir}/skeletons/service/windows/service.h.in")
        set(_aw_svc_impl   "${_aw_service_dir}/skeletons/service/windows/service.cpp.in")

        if(EXISTS "${_aw_svc_header}")
            configure_file(
                "${_aw_svc_header}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.h"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.h")
        endif()

        if(EXISTS "${_aw_svc_impl}")
            configure_file(
                "${_aw_svc_impl}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.cpp"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.cpp")
        endif()

        # --- Windows install script ---
        set(_aw_install_bat "${_aw_service_dir}/skeletons/service/windows/install_service.bat.in")
        if(EXISTS "${_aw_install_bat}")
            configure_file(
                "${_aw_install_bat}"
                "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat"
                @ONLY
            )
        endif()

    else()
        # --- POSIX daemon source ---
        set(_aw_daemon_header "${_aw_service_dir}/skeletons/service/posix/daemon.h.in")
        set(_aw_daemon_impl   "${_aw_service_dir}/skeletons/service/posix/daemon.cpp.in")

        if(EXISTS "${_aw_daemon_header}")
            configure_file(
                "${_aw_daemon_header}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.h"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.h")
        endif()

        if(EXISTS "${_aw_daemon_impl}")
            configure_file(
                "${_aw_daemon_impl}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.cpp"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.cpp")
        endif()

        # --- systemd .service unit file ---
        set(_aw_service_unit "${_aw_service_dir}/skeletons/service/posix/myapp.service.in")
        if(EXISTS "${_aw_service_unit}")
            configure_file(
                "${_aw_service_unit}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service"
                @ONLY
            )
        endif()
    endif()

    # -------------------------------------------------------------------
    # 9. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})

    # -------------------------------------------------------------------
    # 10. Install rules
    # -------------------------------------------------------------------
    include(GNUInstallDirs)

    # Install the binary.
    install(TARGETS ${TARGET}
        RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
    )

    if(_aw_platform STREQUAL "windows")
        # Windows: install the install script to datarootdir/scripts/.
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat")
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/scripts/"
            )
        endif()
    else()
        # Linux: install the .service unit file to systemd directory.
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service")
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/systemd/system/"
            )
        endif()
    endif()
endfunction()
# =============================================================================
# 06_kernel.cmake — Kernel driver archetype
#
# Provides:
#   aw_add_kernel_driver()  — Kernel-mode driver (Windows WDK .sys, Linux .ko)
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.

# ===========================================================================
# aw_add_kernel_driver()
#
# Create a kernel-mode driver target:
#   - Windows: Builds a .sys driver using the WDK (cl.exe with /kernel).
#   - Linux:   Builds a .ko loadable kernel module via Kbuild (make -C
#              <kernel_src> M=<build_dir> modules).
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required; typically .c).
#   HEADERS <files>...           Kernel header files (optional; typically .h).
#   PLATFORM <windows|linux|auto>
#                                Target platform. Default: auto.
#   WDK_VERSION <10.0|11.0>      Windows WDK version (default: 10.0).
#   LINUX_VERSION <6.1|6.6>      Minimum Linux kernel version (default: 6.1).
#   MODULE_NAME <name>           Linux module name (default: derived from TARGET).
#   KERNEL_SRC_DIR <path>        Path to Linux kernel source tree (Linux).
#   WDK_DIR <path>               Path to WDK installation (Windows).
#
# Example:
#   aw_add_kernel_driver(TARGET my_driver
#       SOURCES src/driver.c
#       HEADERS include/driver.h
#       PLATFORM windows
#       WDK_VERSION 10.0
#   )
#
#   aw_add_kernel_driver(TARGET my_module
#       SOURCES src/module.c
#       PLATFORM linux
#       LINUX_VERSION 6.6
#       KERNEL_SRC_DIR /lib/modules/$(uname -r)/build
#   )
# ===========================================================================
function(aw_add_kernel_driver TARGET)
    cmake_parse_arguments(ARG
        ""
        "PLATFORM;WDK_VERSION;LINUX_VERSION;MODULE_NAME;KERNEL_SRC_DIR;WDK_DIR"
        "SOURCES;HEADERS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT TARGET)
        message(FATAL_ERROR
            "aw_add_kernel_driver(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_kernel_driver(${TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_PLATFORM)
        set(ARG_PLATFORM "auto")
    endif()

    if(NOT ARG_WDK_VERSION)
        set(ARG_WDK_VERSION "10.0")
    endif()

    if(NOT ARG_LINUX_VERSION)
        set(ARG_LINUX_VERSION "6.1")
    endif()

    if(NOT ARG_MODULE_NAME)
        set(ARG_MODULE_NAME "${TARGET}")
    endif()

    # -------------------------------------------------------------------
    # 2. Detect platform
    # -------------------------------------------------------------------
    if(ARG_PLATFORM STREQUAL "auto")
        if(CMAKE_SYSTEM_NAME MATCHES "Windows")
            set(_aw_platform "windows")
        elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
            set(_aw_platform "linux")
        else()
            message(FATAL_ERROR
                "aw_add_kernel_driver(${TARGET}): "
                "Cannot auto-detect platform on ${CMAKE_SYSTEM_NAME}. "
                "Specify PLATFORM windows or PLATFORM linux.")
        endif()
    elseif(ARG_PLATFORM STREQUAL "windows")
        set(_aw_platform "windows")
    elseif(ARG_PLATFORM STREQUAL "linux")
        set(_aw_platform "linux")
    else()
        message(FATAL_ERROR
            "aw_add_kernel_driver(${TARGET}): "
            "PLATFORM must be 'windows', 'linux', or 'auto'")
    endif()

    # -------------------------------------------------------------------
    # 3. Create target
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # Windows WDK: use add_executable with no subsystem (produces .sys).
        add_executable(${TARGET} ${ARG_SOURCES})
    else()
        # Linux: create an INTERFACE library as a marker; the actual build
        # happens via Kbuild in a custom command.
        add_library(${TARGET} INTERFACE)
    endif()

    # No ALIAS target — kernel drivers are not imported by other projects.

    # -------------------------------------------------------------------
    # 4. Common compile features & definitions
    # -------------------------------------------------------------------
    target_compile_definitions(${TARGET} PRIVATE
        _KERNEL_MODE
        __KERNEL__
    )

    target_include_directories(${TARGET} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )

    if(ARG_HEADERS)
        target_include_directories(${TARGET} PRIVATE
            ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 5. Platform-specific configuration
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # ------- Windows WDK flags -------
        if(NOT MSVC)
            message(WARNING
                "aw_add_kernel_driver(${TARGET}): "
                "Windows kernel drivers require the MSVC compiler (cl.exe). "
                "Ensure the WDK toolchain is configured.")
        endif()

        target_compile_options(${TARGET} PRIVATE
            /kernel
            /W4
            /Zc:wchar_t
            /Zc:inline
            /permissive-
        )

        target_compile_definitions(${TARGET} PRIVATE
            UNICODE
            _UNICODE
            NTDDI_VERSION=0x0A00000F
            _WIN32_WINNT=0x0A00
        )

        # Link against WDK libraries.
        target_link_libraries(${TARGET} PRIVATE
            ntoskrnl.lib
            wdm.lib
            wdfldr.lib
        )

        if(ARG_WDK_DIR)
            set(_aw_wdk_dir "${ARG_WDK_DIR}")
            target_include_directories(${TARGET} PRIVATE
                "${_aw_wdk_dir}/Include/${ARG_WDK_VERSION}/km"
                "${_aw_wdk_dir}/Include/${ARG_WDK_VERSION}/shared"
            )
            target_link_directories(${TARGET} PRIVATE
                "${_aw_wdk_dir}/Lib/${ARG_WDK_VERSION}/km/x64"
            )
        endif()

        # No install rules — kernel drivers are deployed via specialized
        # mechanisms (inf files, signtool, etc.).

    else()
        # ------- Linux Kbuild configuration -------
        if(NOT ARG_KERNEL_SRC_DIR)
            # Try to detect kernel source from running kernel.
            find_program(_AW_UNAME uname)
            if(_AW_UNAME)
                execute_process(
                    COMMAND ${_AW_UNAME} -r
                    OUTPUT_VARIABLE _AW_KERN_REL
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE _AW_UNAME_RC
                )
                if(_AW_UNAME_RC EQUAL 0 AND _AW_KERN_REL)
                    set(ARG_KERNEL_SRC_DIR
                        "/lib/modules/${_AW_KERN_REL}/build")
                endif()
            endif()
            unset(_AW_UNAME)
            unset(_AW_KERN_REL)
            unset(_AW_UNAME_RC)
        endif()

        if(NOT ARG_KERNEL_SRC_DIR)
            message(WARNING
                "aw_add_kernel_driver(${TARGET}): "
                "KERNEL_SRC_DIR not specified and could not auto-detect. "
                "Set KERNEL_SRC_DIR to your kernel source or headers path.")
            set(ARG_KERNEL_SRC_DIR "/usr/src/linux-headers-$(uname -r)/build")
        endif()

        # Generate Kbuild file.
        set(_aw_kbuild_in
            "${_aw_kernel_dir}/skeletons/kernel/linux/Kbuild.in")
        set(_aw_kbuild_out
            "${CMAKE_CURRENT_BINARY_DIR}/Kbuild")

        if(EXISTS "${_aw_kbuild_in}")
            configure_file(
                "${_aw_kbuild_in}"
                "${_aw_kbuild_out}"
                @ONLY
            )
        else()
            message(FATAL_ERROR
                "aw_add_kernel_driver(${TARGET}): "
                "Kbuild.in skeleton not found at ${_aw_kbuild_in}")
        endif()

        # Generate the module source from skeleton.
        set(_aw_mod_in
            "${_aw_kernel_dir}/skeletons/kernel/linux/module.c.in")
        set(_aw_mod_out
            "${CMAKE_CURRENT_BINARY_DIR}/${ARG_MODULE_NAME}.c")

        if(EXISTS "${_aw_mod_in}")
            configure_file(
                "${_aw_mod_in}"
                "${_aw_mod_out}"
                @ONLY
            )
        endif()

        # Custom target to invoke Kbuild.
        add_custom_target(${TARGET}_build
            COMMAND ${CMAKE_MAKE_PROGRAM}
                -C "${ARG_KERNEL_SRC_DIR}"
                M=${CMAKE_CURRENT_BINARY_DIR}
                modules
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
            COMMENT "Building Linux kernel module ${TARGET}"
            DEPENDS "${_aw_kbuild_out}"
        )

        # Install the .ko module.
        install(FILES "${_aw_mod_out}"
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/modules/${ARG_LINUX_VERSION}/extra/"
            RENAME "${ARG_MODULE_NAME}.ko"
        )
    endif()

    # -------------------------------------------------------------------
    # 6. Apply infrastructure helpers (warnings, sanitizers, coverage)
    #    Note: sanitizers and coverage are typically NOT useful for kernel
    #    drivers, but we keep the hooks for user-space testing targets.
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})

    # Kernel drivers should never have sanitizers or coverage enabled.
    # These helpers become no-ops for kernel targets if the user does not
    # explicitly set AW_..._SANITIZE or AW_..._ENABLE_COVERAGE.
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})

    # Lint is skipped for kernel drivers (clang-tidy does not understand
    # kernel headers).  aw_add_lint is intentionally NOT called here.
endfunction()
