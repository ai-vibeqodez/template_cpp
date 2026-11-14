# Task 03: Shared Library and Plugin Modules

## Goal

Implement `aw_add_shared_library()` and `aw_add_plugin_module()` CMake helper functions in `archetypes/02_shared_plugin.cmake`. These cover shared/dynamic libraries with cross-platform visibility macros, DLL entry points, and a plugin module system with `extern "C"` factory entry points.

## Files to Create/Modify

### Modify
1. **`archetypes/02_shared_plugin.cmake`** — Replace stub with full implementations of `aw_add_shared_library()` and `aw_add_plugin_module()`.

### Create
2. **`archetypes/skeletons/shared/export_macro.hpp.in`** — Template for the `AW_API` visibility macro header.
3. **`archetypes/skeletons/shared/plugin_interface.hpp.in`** — Template for a plugin interface (abstract base class with `extern "C"` factory).
4. **`archetypes/skeletons/shared/tests/test_plugin.cpp.in`** — Template for a Catch2 test of a shared library.
5. **`archetypes/skeletons/shared/CMakeLists.txt.example`** — Example of how to call `aw_add_shared_library()`.
6. **`archetypes/skeletons/plugin/CMakeLists.txt.example`** — Example of how to call `aw_add_plugin_module()`.

## Implementation Details

### 1. `AW_API` Visibility Macro (`export_macro.hpp.in`)

The visibility macro header provides a cross-platform export/import macro:

```cpp
#pragma once

/**
 * @file export_macro.hpp
 * @brief Cross-platform DLL export/import visibility macro.
 */

#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef AW_SHARED_BUILDING
        #define AW_API __declspec(dllexport)
    #else
        #define AW_API __declspec(dllimport)
    #endif
    #define AW_API_LOCAL
#else
    #if __GNUC__ >= 4
        #define AW_API __attribute__((visibility("default")))
        #define AW_API_LOCAL __attribute__((visibility("hidden")))
    #else
        #define AW_API
        #define AW_API_LOCAL
    #endif
#endif
```

- When building the shared library, define `AW_SHARED_BUILDING` (set by CMake helper).
- Consumers automatically get `dllimport` on Windows or `visibility("default")` on GCC/Clang.
- Internal symbols use `AW_API_LOCAL` to reduce the DLL export table.

### 2. `aw_add_shared_library(TARGET ...)`

Signature:
```cmake
aw_add_shared_library(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    HEADERS <header1.hpp> <header2.hpp> ...
    [BASE_DIRS <include>]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
    [EXPORT_MACRO <macro-name>]      # Default: AW_API
    [EXPORT_MACRO_DEFINE <define>]   # Default: <TARGET>_BUILDING
)
```

Implementation:
- Create a `SHARED` library target.
- Set `target_compile_definitions(<target> PRIVATE <EXPORT_MACRO_DEFINE>)` (e.g., `MY_LIB_BUILDING`).
- Include the export macro header in the public headers.
- Use `target_sources(<target> PUBLIC FILE_SET HEADERS ...)`.
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- On Windows: automatically add `WIN32` to `target_sources` with a `DllMain.cpp` skeleton (or provide one).
- On Linux/macOS: no special entry point needed; visibility is controlled by the macro.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- Call `aw_setup_install()`.
- Create ALIAS target.

**DllMain skeleton (Windows):**
```cpp
// DllMain.cpp — Windows DLL entry point
#include <windows.h>

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}
```

**Constructor/Destructor skeleton (POSIX):**
```cpp
// init.cpp — POSIX library initialization
#include <cstdio>

__attribute__((constructor))
static void library_init() {
    // Library initialization code.
}

__attribute__((destructor))
static void library_fini() {
    // Library cleanup code.
}
```

### 3. `aw_add_plugin_module(TARGET ...)`

Signature:
```cmake
aw_add_plugin_module(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    HEADERS <header1.hpp> ...
    [BASE_DIRS <include>]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [FACTORY_NAME <factory_function_name>]  # Default: create_plugin
)
```

Implementation:
- Create a `MODULE` library target (`BUILD_WITH_INSTALL_RPATH` on macOS).
- Plugin modules are not linked into the final executable; they are loaded at runtime via `dlopen`/`LoadLibrary`.
- The factory function is declared `extern "C"` to prevent name mangling.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- **Do NOT call `aw_setup_install()`** — plugins are deployed alongside the host application, not installed to system paths.
- **Do NOT create an ALIAS target** — plugins have no library consumer interface.

**Plugin factory skeleton:**
```cpp
// plugin.cpp — Plugin module with extern "C" factory entry point
extern "C" {

/**
 * @brief Factory function — called by the host application to create a plugin instance.
 * @return A pointer to the plugin interface (caller takes ownership).
 */
AW_API void* create_plugin() {
    return new MyPlugin();
}

/**
 * @brief Destroy function — called by the host application to release the plugin.
 * @param[in] plugin Pointer returned by create_plugin().
 */
AW_API void destroy_plugin(void* plugin) {
    delete static_cast<MyPlugin*>(plugin);
}

} // extern "C"
```

### 4. Plugin Interface Skeleton

```cpp
#pragma once

/**
 * @file plugin_interface.hpp
 * @brief Abstract plugin interface — all plugins must implement this.
 */

#include <string_view>

namespace aw::plugin {

/**
 * @class IPlugin
 * @brief Abstract base class for all plugin modules.
 */
class IPlugin {
public:
    virtual ~IPlugin() = default;

    /**
     * @brief Returns the plugin name.
     */
    [[nodiscard]] virtual std::string_view name() const = 0;

    /**
     * @brief Returns the plugin version.
     */
    [[nodiscard]] virtual std::string_view version() const = 0;

    /**
     * @brief Initialize the plugin. Called once after creation.
     */
    virtual void initialize() = 0;

    /**
     * @brief Cleanup the plugin. Called once before destruction.
     */
    virtual void cleanup() = 0;
};

} // namespace aw::plugin
```

## Acceptance Criteria

1. **`aw_add_shared_library()` compiles**: A SHARED library target builds without errors on the current platform (Windows DLL or Linux/macOS shared object).
2. **`aw_add_plugin_module()` compiles**: A MODULE library target builds without errors.
3. **AW_API macro works**: Symbols marked `AW_API` are exported on Windows (`__declspec(dllexport)`) and GCC/Clang (`__attribute__((visibility("default")))`).
4. **Windows DllMain present**: When building on Windows, a `DllMain.cpp` skeleton is included.
5. **POSIX constructor/destructor present**: When building on Linux/macOS, a `init.cpp` skeleton with `__attribute__((constructor))`/`__attribute__((destructor))` is included.
6. **Plugin factory is `extern "C"`**: The factory function has C linkage to prevent name mangling.
7. **Skeletons follow conventions**: All skeleton files follow `docs/CPP_GUIDELINES.md`.
8. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes.
