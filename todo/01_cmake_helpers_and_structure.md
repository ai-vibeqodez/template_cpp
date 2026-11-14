# Task 01: CMake Helpers & Structure

## Goal

Refactor `cmake/AwProjectDefaults.cmake` to introduce a clean `archetypes/` directory layout and provide the foundational CMake helper functions that all subsequent tasks will build upon. The primary objective is to make the `template-cpp` repository support **conflict-free manual `git pull template main` updates** while keeping the root `CMakeLists.txt` minimal and project-owned.

## Files to Create/Modify

### Modify
1. **`cmake/AwProjectDefaults.cmake`** — Add new `aw_add_*` helper functions; restructure existing code for extensibility.
2. **`CMakeLists.txt`** — Simplify to a minimal script that sets `AW_PROJECT_PREFIX`, includes the shared CMake infrastructure, and delegates to archetype helpers.

### Create
3. **`archetypes/CMakeLists.txt`** — Directory-level CMake that aggregates archetype helpers (future tasks will add subdirectories).
4. **`archetypes/01_core.cmake`** — Contains `aw_add_header_only_library()` and `aw_add_static_library()` stubs (full implementation deferred to Task 02).
5. **`archetypes/02_shared_plugin.cmake`** — Contains `aw_add_shared_library()` and `aw_add_plugin_module()` stubs (full implementation deferred to Task 03).
6. **`archetypes/03_modules.cmake`** — Contains `aw_add_cxx_module_library()` stub (full implementation deferred to Task 04).
7. **`archetypes/04_executables.cmake`** — Contains `aw_add_executable()` and `aw_add_gui_executable()` stubs (full implementation deferred to Task 05).
8. **`archetypes/05_service.cmake`** — Contains `aw_add_service_executable()` stub (full implementation deferred to Task 06).
9. **`archetypes/06_kernel.cmake`** — Contains `aw_add_kernel_driver()` stub (full implementation deferred to Task 07).

## Implementation Details

### 1. Refactor `cmake/AwProjectDefaults.cmake`

The existing file already provides:
- Guard pattern (`if(TARGET aw::core_defaults) return()`)
- `AW_PROJECT_PREFIX` variable resolution
- Top-level detection
- C++20/23 standard enforcement
- Warnings-as-errors (`_aw_set_warnings`)
- Sanitizers (`_aw_apply_sanitizers`)
- Code coverage (`_aw_apply_coverage`)
- Install & package export (`_aw_setup_install`)
- Test discovery (`_aw_setup_tests`)
- Lint helper (`_aw_add_lint`)

**Changes required:**
- Extract `_aw_setup_install` into a public `aw_setup_install()` function (rename by removing `_aw_` prefix, making it callable from `CMakeLists.txt`).
- Extract `_aw_setup_tests` into a public `aw_setup_tests()` function.
- Extract `_aw_add_lint` into a public `aw_add_lint()` function.
- Add documentation comments to each new public function explaining parameters and usage.
- Keep internal helper functions prefixed with `_aw_`.
- Add a new `aw_include_archetypes(<dir>)` function that `include()`s all `.cmake` files from the given directory (used by `CMakeLists.txt` to load archetype helpers).

### 2. Simplify Root `CMakeLists.txt`

The current `CMakeLists.txt` is 69 lines with direct `add_library`, `target_compile_features`, `target_include_directories`, `target_sources`, and `target_link_libraries` calls.

**Target structure (approximately 20–25 lines):**
```cmake
cmake_minimum_required(VERSION 3.23)

# Version from VERSION file (unchanged)
file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
             "${CMAKE_CURRENT_LIST_DIR}/VERSION")

project(template_cpp VERSION ${PROJECT_VERSION} LANGUAGES CXX)

# Dependencies
find_package(Threads REQUIRED)

# Include shared CMake infrastructure
include(cmake/AwProjectDefaults.cmake)

# Set project prefix
set(AW_PROJECT_PREFIX "TEMPLATE_CPP")

# ── Load archetype helpers ───────────────────────────────────────────
include(archetypes/01_core.cmake)
include(archetypes/02_shared_plugin.cmake)
include(archetypes/03_modules.cmake)
include(archetypes/04_executables.cmake)
include(archetypes/05_service.cmake)
include(archetypes/06_kernel.cmake)

# ── Use archetype helpers (stub for now, fleshed out by Tasks 02–07) ─
# aw_add_static_library(${PROJECT_NAME}
#     SOURCES src/hello.cpp
#     HEADERS include/aw/template_cpp/hello.hpp
#     LINK_LIBRARIES Threads::Threads
# )

# ── Examples, Tests, Install (using public helpers) ──────────────────
option(AW_TEMPLATE_CPP_BUILD_EXAMPLES "..." ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})
if(AW_TEMPLATE_CPP_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

option(AW_TEMPLATE_CPP_BUILD_TESTS "..." ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})
if(AW_TEMPLATE_CPP_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

option(AW_TEMPLATE_CPP_INSTALL "..." ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})
```

The key principle: **root `CMakeLists.txt` must never conflict with template updates**. It should only contain project-specific settings, option declarations, and calls to archetype helpers. The archetype helpers themselves live under `archetypes/` and are updated by `git pull template main`.

### 3. Create `archetypes/` Directory Structure

Each `.cmake` file in `archetypes/` should:
- Start with a header comment describing its purpose.
- Define exactly one or two `aw_add_*` public functions.
- Call `_aw_set_warnings`, `_aw_apply_sanitizers`, `_aw_apply_coverage`, and `_aw_add_lint` internally (passing the target name).
- Call `aw_setup_install` if the target is a library.
- Be idempotent (safe to `include()` multiple times — use `if(TARGET ...)` guards if needed).

### 4. Create `archetypes/CMakeLists.txt`

A simple aggregator that includes all archetype `.cmake` files:
```cmake
# Archetype helpers — loaded by root CMakeLists.txt
include("${CMAKE_CURRENT_LIST_DIR}/01_core.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/02_shared_plugin.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/03_modules.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/04_executables.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/05_service.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/06_kernel.cmake")
```

### 5. Stub Files (Tasks 02–07 Will Flesh These Out)

Each stub file should define its `aw_add_*` function with a placeholder body that prints a `message(STATUS "...")` and creates a minimal target. For example:

```cmake
# archetypes/01_core.cmake
function(aw_add_static_library TARGET)
    cmake_parse_arguments(ARG "" "SOURCES;HEADERS;LINK_LIBRARIES" "" ${ARGN})
    message(STATUS "[archetype] aw_add_static_library(${TARGET}) — stub, full impl in Task 02")
    # TODO: Task 02 will implement full STATIC library with FILE_SET HEADERS
endfunction()
```

## Acceptance Criteria

1. **Build succeeds**: `cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build --parallel` completes with zero errors.
2. **Tests pass**: `ctest --test-dir build --output-on-failure` runs all existing tests successfully.
3. **Root `CMakeLists.txt` is simplified**: reduced from 69 lines to ~25 lines, with all library target logic delegated to archetype helpers.
4. **`archetypes/` directory exists** with 6 `.cmake` stub files plus the aggregator `CMakeLists.txt`.
5. **Public helper functions** (`aw_setup_install`, `aw_setup_tests`, `aw_add_lint`, `aw_include_archetypes`) are documented and callable from `CMakeLists.txt`.
6. **`git pull template main` safety**: modifying only `archetypes/` and `cmake/` files does not conflict with root `CMakeLists.txt` (project-owned).
7. **No regressions**: all existing functionality (library build, tests, examples, install rules, sanitizers, coverage) continues to work.
