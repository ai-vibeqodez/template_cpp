# Task 02: Header-Only and Static Libraries

## Goal

Implement `aw_add_header_only_library()` and `aw_add_static_library()` CMake helper functions in `archetypes/01_core.cmake`. These cover the two most common library archetypes: header-only libraries (INTERFACE targets with `FILE_SET HEADERS`) and traditional static libraries (STATIC targets with starter skeletons and Catch2 tests).

## Files to Create/Modify

### Modify
1. **`archetypes/01_core.cmake`** — Replace stub with full implementations of `aw_add_header_only_library()` and `aw_add_static_library()`.
2. **`archetypes/CMakeLists.txt`** — No changes needed (already includes this file).

### Create
3. **`archetypes/skeletons/header_only/example.hpp.in`** — Template for a header-only library public header.
4. **`archetypes/skeletons/static/example_lib.hpp.in`** — Template for a static library public header with `AW_API` macro placeholder.
5. **`archetypes/skeletons/static/example_lib.cpp.in`** — Template for a static library implementation file.
6. **`archetypes/skeletons/static/tests/test_example.cpp.in`** — Template for a Catch2 v3 test file.
7. **`archetypes/skeletons/static/CMakeLists.txt.example`** — Example of how to call `aw_add_static_library()` from a project's root `CMakeLists.txt`.
8. **`archetypes/skeletons/header_only/CMakeLists.txt.example`** — Example of how to call `aw_add_header_only_library()` from a project's root `CMakeLists.txt`.

## Implementation Details

### 1. `aw_add_header_only_library(TARGET ...)`

Signature:
```cmake
aw_add_header_only_library(TARGET <target-name>
    [HEADERS <header1.hpp> <header2.hpp> ...]
    [BASE_DIRS <include>]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
)
```

Implementation:
- Create an `INTERFACE` library target.
- Use `target_sources(<target> PUBLIC FILE_SET HEADERS BASE_DIRS <base_dirs> FILES <headers>)` (CMake 3.12+).
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set `target_compile_definitions` and `target_link_libraries` as specified.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, and `_aw_add_lint()` internally (all no-op for INTERFACE targets when not top-level).
- Call `aw_setup_install()` for install rules.
- Create an ALIAS target: `add_library(<namespace>::<target> ALIAS <target>)` where `<namespace>` is derived from `AW_PROJECT_PREFIX` (e.g., `aw::tpl`).

### 2. `aw_add_static_library(TARGET ...)`

Signature:
```cmake
aw_add_static_library(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    HEADERS <header1.hpp> <header2.hpp> ...
    [BASE_DIRS <include>]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
)
```

Implementation:
- Create a `STATIC` library target (default active target — static is the safer choice for shared libraries).
- Use `target_sources(<target> PUBLIC FILE_SET HEADERS BASE_DIRS <base_dirs> FILES <headers>)`.
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set `target_include_directories(<target> PUBLIC $<BUILD_INTERFACE:...> $<INSTALL_INTERFACE:...>)`.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, and `_aw_add_lint()` internally.
- Call `aw_setup_install()` for install rules.
- Create an ALIAS target: `add_library(<namespace>::<target> ALIAS <target>)`.
- Link specified `LINK_LIBRARIES`.

### 3. Starter Skeletons

Each skeleton file should:
- Follow `docs/CPP_GUIDELINES.md` naming conventions (PascalCase types, snake_case functions, trailing_underscore_ members).
- Include proper Doxygen documentation blocks.
- Use `#pragma once`, own-header-first include order, and the `aw::` namespace pattern.
- Use `.in` extension for templates that will be copied/modified by the user.

**`example.hpp.in` (header-only):**
```cpp
#pragma once

/**
 * @file example.hpp
 * @brief Brief one-line description.
 */

#include <string_view>

namespace aw::example {

/**
 * @class Example
 * @brief A header-only utility class.
 */
class [[nodiscard]] Example {
public:
    /**
     * @brief Returns a greeting string.
     * @param[in] name The name to greet.
     * @return A greeting message.
     */
    [[nodiscard]] static std::string_view greet(std::string_view name);
};

} // namespace aw::example
```

**`example_lib.hpp.in` (static):**
```cpp
#pragma once

/**
 * @file example_lib.hpp
 * @brief Public API for the static library.
 */

#include <string_view>

namespace aw::example_lib {

class [[nodiscard]] ExampleLib {
public:
    [[nodiscard]] static std::string_view greet(std::string_view name);
    [[nodiscard]] static std::string_view version();
};

} // namespace aw::example_lib
```

**`example_lib.cpp.in`:**
```cpp
#include <aw/example_lib/example_lib.hpp>

#include <sstream>

namespace aw::example_lib {

std::string_view ExampleLib::greet(std::string_view name) {
    // ... implementation
    return "Hello";
}

std::string_view ExampleLib::version() {
    return EXAMPLE_LIB_VERSION;
}

} // namespace aw::example_lib
```

**`test_example.cpp.in`:**
```cpp
#include <catch2/catch_test_macros.hpp>
#include <aw/example_lib/example_lib.hpp>

TEST_CASE("ExampleLib::greet returns formatted message", "[example][greet]") {
    REQUIRE(ExampleLib::greet("World") == "Hello");
}

TEST_CASE("ExampleLib::version returns non-empty string", "[example][version]") {
    REQUIRE(!ExampleLib::version().empty());
}
```

### 4. Example CMakeLists.txt Files

**`CMakeLists.txt.example` (static):**
```cmake
# In your project's root CMakeLists.txt:
aw_add_static_library(TARGET my_lib
    SOURCES src/my_lib.cpp
    HEADERS include/aw/my_lib/my_lib.hpp
    BASE_DIRS include
    LINK_LIBRARIES Threads::Threads
    COMPILE_DEFINITIONS MY_LIB_VERSION="1.0.0"
)
```

**`CMakeLists.txt.example` (header-only):**
```cmake
# In your project's root CMakeLists.txt:
aw_add_header_only_library(TARGET my_header_lib
    HEADERS include/aw/my_header_lib/my_header_lib.hpp
    BASE_DIRS include
    LINK_LIBRARIES Threads::Threads
)
```

## Acceptance Criteria

1. **`aw_add_header_only_library()` compiles**: A project that calls it with a valid INTERFACE target builds without errors.
2. **`aw_add_static_library()` compiles**: A project that calls it with a valid STATIC target builds without errors.
3. **FILE_SET HEADERS is used**: Both functions use `target_sources(... FILE_SET HEADERS ...)` for header installation.
4. **ALIAS targets created**: Both functions create `aw::<prefix>::<target>` ALIAS targets.
5. **Install rules generated**: Both functions call `aw_setup_install()` and produce correct install paths.
6. **Skeletons follow conventions**: All skeleton files follow `docs/CPP_GUIDELINES.md` (naming, Doxygen, include order, `#pragma once`).
7. **Skeletons are copy-paste ready**: The `.in` files and example `CMakeLists.txt` files provide a clear path for a user to create a new header-only or static library.
8. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes.
