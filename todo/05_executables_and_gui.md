# Task 05: Executables and GUI

## Goal

Implement `aw_add_executable()` and `aw_add_gui_executable()` CMake helper functions in `archetypes/04_executables.cmake`. These cover CLI executables and cross-platform GUI executables (Win32 subsystem without console, macOS `.app` bundle, Linux binary).

## Files to Create/Modify

### Modify
1. **`archetypes/04_executables.cmake`** — Replace stub with full implementations of `aw_add_executable()` and `aw_add_gui_executable()`.

### Create
2. **`archetypes/skeletons/cli/main.cpp.in`** — Template for a CLI executable `main()` with argument parsing skeleton.
3. **`archetypes/skeletons/gui/win32/main.cpp.in`** — Template for a Win32 GUI executable (WinMain entry point).
4. **`archetypes/skeletons/gui/win32/resource.h.in`** — Template for Win32 resource header (icon, version info).
5. **`archetypes/skeletons/gui/win32/icon.rc.in`** — Template for Win32 resource script.
6. **`archetypes/skeletons/gui/macos/AppDelegate.swift.in`** — Template for macOS app delegate (SwiftUI).
7. **`archetypes/skeletons/gui/macos/Info.plist.in`** — Template for macOS `Info.plist`.
8. **`archetypes/skeletons/gui/linux/main.cpp.in`** — Template for a Linux GUI executable (plain binary, no subsystem).
9. **`archetypes/skeletons/gui/linux/app.desktop.in`** — Template for a Linux `.desktop` entry.
10. **`archetypes/skeletons/gui/linux/icons/symbolic.svg.in`** — Template for a Linux app icon.
11. **`archetypes/skeletons/gui/CMakeLists.txt.example`** — Example of how to call `aw_add_gui_executable()`.

## Implementation Details

### 1. `aw_add_executable(TARGET ...)` — CLI Executable

Signature:
```cmake
aw_add_executable(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
    [INSTALL_DESTINATION <bin>]  # Default: ${CMAKE_INSTALL_BINDIR}
)
```

Implementation:
- Create a standard `EXECUTABLE` target (console subsystem on all platforms).
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set `target_link_libraries()` and `target_compile_definitions()` as specified.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- Install to `${CMAKE_INSTALL_BINDIR}` via `install(TARGETS <target> RUNTIME DESTINATION ...)`.
- **No ALIAS target** — executables are not imported by other projects.

**CLI main skeleton:**
```cpp
// main.cpp — CLI executable entry point
#include <iostream>
#include <string>
#include <string_view>

/**
 * @brief Print usage information.
 */
static void print_usage(std::string_view program_name) {
    std::cerr << "Usage: " << program_name << " [OPTIONS]\n"
              << "Options:\n"
              << "  -h, --help     Show this help message\n"
              << "  -v, --version  Show version information\n"
              << "  -V, --verbose  Enable verbose output\n";
}

/**
 * @brief Parse command-line arguments.
 * @return true if parsing succeeded, false if --help was requested.
 */
static bool parse_args(int argc, char* argv[], bool& verbose) {
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            print_usage(argv[0]);
            return false;
        }
        if (arg == "-v" || arg == "--version") {
            std::cout << "version 1.0.0\n";
            return false;
        }
        if (arg == "-V" || arg == "--verbose") {
            verbose = true;
        }
    }
    return true;
}

int main(int argc, char* argv[]) {
    bool verbose = false;
    if (!parse_args(argc, argv, verbose)) {
        return 0;  // --help or --version requested
    }

    // Application logic here.
    std::cout << "Hello from CLI executable!\n";

    return 0;
}
```

### 2. `aw_add_gui_executable(TARGET ...)` — Cross-Platform GUI

Signature:
```cmake
aw_add_gui_executable(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    [HEADERS <header1.hpp> ...]
    [RESOURCES <res1.rc> <res2.rc> ...]  # Platform-specific resource files
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
    [APP_NAME <name>]                    # Default: derived from target
    [APP_ICON <icon_file>]               # Platform-specific icon file
    [INSTALL_DESTINATION <dir>]          # Default: ${CMAKE_INSTALL_BINDIR}
)
```

Implementation:
- **Detect platform** using `CMAKE_SYSTEM_NAME` (Windows, Darwin, Linux).
- **Windows**: Set `WIN32` on the target (creates a GUI subsystem executable without console window). Include `WIN32` in `target_sources` with `WIN32` keyword. Add DllMain if not provided.
- **macOS**: Create an `.app` bundle using `macos_bundle` (CMake 3.17+) or manual `add_custom_command`. Set `CFBundleName`, `CFBundleExecutable`, `CFBundleIdentifier`, `CFBundleIconFile` in `Info.plist`.
- **Linux**: Standard executable (no subsystem flag). Optionally install a `.desktop` file and icon for desktop integration.
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set platform-specific compile definitions (`WIN32`, `__APPLE__`, etc.).
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- Install rules:
  - Windows: binary to `${CMAKE_INSTALL_BINDIR}`.
  - macOS: `.app` bundle to `${CMAKE_INSTALL_PREFIX}/Applications/`.
  - Linux: binary to `${CMAKE_INSTALL_BINDIR}`, `.desktop` to `${CMAKE_INSTALL_DATAROOTDIR}/applications/`, icon to `${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps/`.
- **No ALIAS target** — executables are not imported by other projects.

**Win32 GUI main skeleton:**
```cpp
// main.cpp — Win32 GUI executable entry point (WinMain)
#include <windows.h>

/**
 * @brief WinMain entry point for a GUI application.
 * Creates a GUI subsystem executable (no console window).
 */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nCmdShow;

    // Application initialization.
    // TODO: Create window, message loop, etc.

    return 0;
}
```

**macOS App Delegate (SwiftUI):**
```swift
// AppDelegate.swift — macOS app entry point
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello from macOS GUI!")
                .padding()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
```

**Linux GUI main skeleton:**
```cpp
// main.cpp — Linux GUI executable entry point
#include <iostream>

int main() {
    // Application logic here.
    // For a full GUI, link against GTK4, Qt6, or Dear ImGui.
    std::cout << "Hello from Linux GUI executable!\n";
    return 0;
}
```

**Linux `.desktop` template:**
```ini
[Desktop Entry]
Name=@APP_NAME@
Exec=@APP_NAME@
Icon=@APP_NAME@
Type=Application
Categories=Utility;
Terminal=false
```

## Acceptance Criteria

1. **`aw_add_executable()` compiles**: A CLI executable target builds without errors and produces a console binary on all platforms.
2. **`aw_add_gui_executable()` compiles**: A GUI executable target builds without errors.
3. **Windows GUI target has `WIN32` flag**: The resulting executable runs as a GUI subsystem (no console window appears).
4. **macOS bundle**: On Darwin, the target produces a `.app` bundle with a valid `Info.plist`.
5. **Linux desktop integration**: On Linux, the `.desktop` file and icon are installed to the correct paths.
6. **CLI argument parsing skeleton**: The CLI `main.cpp.in` includes a basic argument parser with `--help`, `--version`, and `--verbose`.
7. **Skeletons follow conventions**: All skeleton files follow `docs/CPP_GUIDELINES.md`.
8. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes.
