# Task 04: C++20 Modules

## Goal

Implement `aw_add_cxx_module_library()` CMake helper function in `archetypes/03_modules.cmake`. This provides a C++20 module target using CMake 3.28+ `FILE_SET CXX_MODULES` with a starter skeleton and compiler compatibility notes.

## Files to Create/Modify

### Modify
1. **`archetypes/03_modules.cmake`** — Replace stub with full implementation of `aw_add_cxx_module_library()`.

### Create
2. **`archetypes/skeletons/module/ModuleCard.cppm.in`** — Template for a C++20 module implementation unit.
3. **`archetypes/skeletons/module/ModuleCard.hin.in`** — Template for a C++20 module interface unit (`.hin` extension for header-only interface).
4. **`archetypes/skeletons/module/tests/test_module.cpp.in`** — Template for a Catch2 test that imports the module.
5. **`archetypes/skeletons/module/CMakeLists.txt.example`** — Example of how to call `aw_add_cxx_module_library()`.
6. **`archetypes/skeletons/module/COMPATIBILITY.md`** — Compiler compatibility notes for C++20 modules.

## Implementation Details

### 1. `aw_add_cxx_module_library(TARGET ...)`

Signature:
```cmake
aw_add_cxx_module_library(TARGET <target-name>
    MODULES <module1.cppm> <module2.cppm> ...
    HEADERS <header1.hpp> <header2.hpp> ...
    [BASE_DIRS <include>]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
    [MODULE_NAME <logical-module-name>]  # Default: derived from target
)
```

Implementation:
- **CMake version check**: Require CMake 3.28+ (when `FILE_SET CXX_MODULES` was introduced). If CMake < 3.28, emit `message(WARNING "C++20 modules require CMake 3.28+; falling back to traditional header-based build")` and create a regular STATIC library instead as a fallback.
- Create a `STATIC` library target (CMake does not support `MODULE` for C++ modules — modules are compiled into a static library that is then linked).
- Use `target_sources(<target> PUBLIC FILE_SET CXX_MODULES FILES <modules>)` (CMake 3.28+).
- Use `target_sources(<target> PUBLIC FILE_SET HEADERS FILES <headers>)` for interface headers.
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set `target_compile_definitions(<target> PRIVATE <MODULE_NAME>=1)` for feature detection.
- On MSVC: enable `/std:c++20` and `/experimental:module` (or `/std:c++latest`). MSVC module support is still evolving — document this.
- On Clang: enable `-fmodules-ts` (C++20 modules are TS-based, not yet standard in Clang).
- On GCC: enable `-fmodules` (GCC module support is experimental).
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- Call `aw_setup_install()` for install rules.
- Create ALIAS target.

### 2. Module Interface Unit Skeleton (`ModuleCard.hin.in`)

The `.hin` extension (header interface unit) is a convention for C++20 module interfaces. The actual extension may vary by compiler:

```cpp
// ModuleCard.hin — C++20 module interface unit
// Compile with: g++ -fmodules-ts -c ModuleCard.hin  (GCC)
//               clang++ -fmodules-ts -c ModuleCard.hin  (Clang)
//               cl /experimental:module /c ModuleCard.cppm  (MSVC)

export module ModuleCard;

#include <string_view>

/**
 * @export ModuleCard
 * @brief Exported module interface — consumers use `import ModuleCard;`.
 */
export namespace aw::module_card {

/**
 * @class ModuleCard
 * @brief A C++20 module-based utility class.
 */
class [[nodiscard]] ModuleCard {
public:
    /**
     * @brief Returns a greeting string.
     * @param[in] name The name to greet.
     * @return A greeting message.
     */
    [[nodiscard]] static std::string_view greet(std::string_view name);
};

} // namespace aw::module_card
```

### 3. Module Implementation Unit Skeleton (`ModuleCard.cppm.in`)

```cpp
// ModuleCard.cppm — C++20 module implementation unit
module ModuleCard;

#include <sstream>

namespace aw::module_card {

std::string_view ModuleCard::greet(std::string_view name) {
    return "Hello from C++20 module";
}

} // namespace aw::module_card
```

### 4. Test Skeleton (`test_module.cpp.in`)

```cpp
#include <catch2/catch_test_macros.hpp>

// Import the C++20 module instead of including a header
import ModuleCard;

TEST_CASE("ModuleCard::greet returns formatted message", "[module][greet]") {
    using namespace aw::module_card;
    REQUIRE(ModuleCard::greet("World") == "Hello from C++20 module");
}
```

### 5. Compiler Compatibility Notes (`COMPATIBILITY.md`)

```markdown
# C++20 Module Compiler Compatibility

| Compiler | Version | Support Level | Flags |
|----------|---------|---------------|-------|
| **GCC** | 13+ | Partial (TS-based) | `-fmodules-ts` |
| **GCC** | 14+ | Improved | `-fmodules-ts` |
| **Clang** | 15+ | Partial (TS-based) | `-fmodules-ts` |
| **Clang** | 17+ | Improved | `-fmodules-ts` |
| **MSVC** | 19.37+ | Limited (`/experimental:module`) | `/std:c++20 /experimental:module` |
| **MSVC** | 19.40+ | Better | `/std:c++latest /experimental:module` |

## Important Notes

1. **CMake 3.28+ required** for `FILE_SET CXX_MODULES`.
2. **Modules are not yet a C++20 standard feature** in most compilers — they use the C++ Modules TS.
3. **Module interface units** (`.hin` / `.cppm` with `export module`) define the public API.
4. **Module implementation units** (`.cppm` with `module`) contain the implementation.
5. **Consumers** use `import ModuleName;` instead of `#include`.
6. **Header units** (`import "header.h";`) are a C++23 feature supported in Clang 15+ and MSVC 19.37+.
7. **Build system complexity**: modules change the compilation model significantly — precompiled modules, module dependencies, and incremental build support vary by compiler.
8. **Recommendation**: Use modules for performance-critical libraries where the build system supports them. Fall back to traditional headers for maximum compatibility.
```

## Acceptance Criteria

1. **`aw_add_cxx_module_library()` compiles**: A module library target builds without errors on a compiler that supports C++20 modules (Clang 15+ with `-fmodules-ts` is the most reliable).
2. **CMake version check works**: On CMake < 3.28, a clear warning is emitted and a fallback STATIC library is created.
3. **FILE_SET CXX_MODULES is used**: When CMake >= 3.28, `target_sources(... FILE_SET CXX_MODULES ...)` is called.
4. **Compiler-specific flags are set**: Clang gets `-fmodules-ts`, MSVC gets `/experimental:module`, GCC gets `-fmodules-ts`.
5. **Module interface and implementation skeletons follow conventions**: Proper `export module` / `import` syntax with Doxygen documentation.
6. **COMPATIBILITY.md is accurate**: Documents the current state of C++20 module support across compilers.
7. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes (modules are opt-in; the default `template_cpp` library remains header/static-based).
