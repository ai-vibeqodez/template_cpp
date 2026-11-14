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

function(_aw_setup_install TARGET EXPORT_NAME NAMESPACE INCLUDE_DIR)
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
function(_aw_setup_tests TEST_EXECUTABLE)
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
function(_aw_add_lint TARGET)
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
