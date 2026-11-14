# Task 08: Docs and Guidelines

## Goal

Update `docs/CPP_GUIDELINES.md` and `README.md` to document all 7 archetypes, the CMake helper functions, and the 4-step `git pull template main` workflow. This is the final task that ties everything together with comprehensive, user-facing documentation.

## Files to Create/Modify

### Modify
1. **`docs/CPP_GUIDELINES.md`** — Add ABI/visibility rules, kernel-mode constraints, and module-specific guidelines.
2. **`README.md`** — Document all archetypes, CMake helpers, project layout with archetypes, and the 4-step `git pull template main` workflow.
3. **`archetypes/skeletons/README.md`** — New file: index of all skeleton templates with descriptions.

### Create
4. **`archetypes/skeletons/README.md`** — A single entry-point document that lists all skeletons organized by archetype, with links to the relevant `.in` files and a "how to use" guide.

## Implementation Details

### 1. Update `docs/CPP_GUIDELINES.md`

Add the following new sections to the existing document:

#### 12. ABI and Visibility Rules

```markdown
## 12. ABI and Visibility Rules

### 12.1 Export Macros

- **Static libraries**: No export macro needed — all symbols are linked directly.
- **Shared libraries**: Use `AW_API` (from `export_macro.hpp`) for all public symbols. Internal symbols use `AW_API_LOCAL`.
- **Kernel drivers**: No export macros — kernel drivers are loaded directly into kernel space.
- **Plugins**: Use `extern "C"` for factory functions to prevent name mangling.

### 12.2 ABI Stability

- **Public headers must be ABI-stable**: Never change the layout of public classes, add/remove virtual functions, or reorder virtual function tables.
- **Pimpl idiom**: For headers that may change, use the Pimpl pattern (`class Impl;` in header, `std::unique_ptr<Impl>` in class body).
- **Versioning**: Use `@version` in Doxygen and expose a `version()` function. Track API changes in `CHANGELOG.md`.
- **No template instantiation in headers**: Template code must be in the header itself (it is its own translation unit). Do not export instantiated templates from a shared library.

### 12.3 Symbol Visibility

- **GCC/Clang**: Compile shared libraries with `-fvisibility=hidden` and mark only public symbols with `AW_API`.
- **MSVC**: Use `__declspec(dllexport)` / `__declspec(dllimport)` via `AW_API`. The build system defines `AW_SHARED_BUILDING` when building the shared library.
- **Export table size**: Keep the export table small — only export what is necessary. Large export tables increase load time and DLL bloat.
```

#### 13. Kernel-Mode Constraints

```markdown
## 13. Kernel-Mode Constraints

### 13.1 General Rules

- **No user-space CRT**: Kernel drivers cannot use `malloc`, `free`, `new`, `delete`, `printf`, `cout`, or any user-space standard library.
- **No exceptions**: C++ exceptions are not supported in kernel mode. Use `NTSTATUS` (Windows) or `int` return codes (Linux).
- **No threading primitives**: Use kernel synchronization primitives (`KEVENT`, `KMUTEX`, `spin_lock`, `mutex_lock`).
- **No dynamic linking**: Kernel drivers are loaded directly into kernel space.

### 13.2 Windows WDK

- Target minimum Windows version via `NTDDI_VERSION` and `_WIN32_WINNT`.
- Use `WDF` (Windows Driver Framework) for modern drivers.
- Sign all drivers for Windows 10+: WHQL certification or test signing.

### 13.3 Linux Kernel

- Target minimum kernel version via `LINUX_VERSION_CODE` and `KERNEL_VERSION()`.
- License must be GPL-compatible (`MODULE_LICENSE("GPL")`).
- Use `pr_info`, `pr_err`, `dev_info` for logging.
- Build against a specific kernel source tree.

See `archetypes/skeletons/kernel/README_KERNEL.md` for detailed guidelines.
```

#### 14. C++20 Module Guidelines

```markdown
## 14. C++20 Module Guidelines

### 14.1 Module Units

- **Interface units** (`.hin` / `.cppm` with `export module`): Define the public API.
- **Implementation units** (`.cppm` with `module`): Contain the implementation.
- **Header units** (`.h` / `.hpp` imported via `import "header.h";`): C++23 feature for importing traditional headers as modules.

### 14.2 Compiler Support

| Compiler | Version | Support Level |
|----------|---------|---------------|
| GCC | 13+ | Partial (TS-based) |
| Clang | 15+ | Partial (TS-based) |
| MSVC | 19.37+ | Limited (`/experimental:module`) |

### 14.3 Best Practices

- Prefer modules for performance-critical libraries where the build system supports them.
- Fall back to traditional headers for maximum compatibility.
- Document module dependencies: a module that imports another module must declare this in its interface unit.
- Header units (`import "header.h";`) are a C++23 feature — use `#include` for broader compatibility.

See `archetypes/skeletons/module/COMPATIBILITY.md` for detailed compatibility notes.
```

### 2. Update `README.md`

Rewrite `README.md` to include:

#### Updated Quick Start (4-Step `git pull template main` Workflow)

```markdown
### Bootstrap a new project

```sh
# Step 1: Clone this template (shallow, keeps history)
git clone --depth 1 https://github.com/ai-warevo/template-cpp.git my-project
cd my-project

# Step 2: Remove the template remote and re-initialize
git remote remove template
git init

# Step 3: Add your own remote (optional, for now)
git remote add origin git@github.com:your-org/my-project.git

# Step 4: Choose your archetype(s) — see below for available archetypes
# Edit CMakeLists.txt to use aw_add_* helpers from archetypes/
```

### Pull future template updates

```sh
# Step 1: Add the template remote (one-time, if you removed it)
git remote add template https://github.com/ai-warevo/template-cpp.git

# Step 2: Pull template updates — no merge conflicts guaranteed
git pull template main

# Step 3: Resolve any conflicts (should not happen with the archetypes design)
# Step 4: Rebuild and test
cmake -B build && cmake --build build && ctest --test-dir build
```

The 4 steps are:
1. `git remote add template ...`
2. `git pull template main`
3. Resolve conflicts (if any)
4. Rebuild and test

#### Updated Features Section

```markdown
## ✨ Features

* **Conflict-free template updates:** Bootstrap once with `git clone --depth 1`, keep `template` as a remote, pull updates with `git pull template main` — no merge conflicts.
* **7 C++ archetypes:** Header-only, static, shared, plugin, C++20 modules, executables (CLI + GUI), system services, and kernel drivers.
* **Shared CMake infrastructure:** `cmake/AwProjectDefaults.cmake` provides sanitizers (ASan/TSan), code coverage, warnings-as-errors, and `FetchContent`-aware target export — all automatically disabled when consumed as a dependency.
* **CMake helper functions:** `aw_add_header_only_library()`, `aw_add_static_library()`, `aw_add_shared_library()`, `aw_add_plugin_module()`, `aw_add_cxx_module_library()`, `aw_add_executable()`, `aw_add_gui_executable()`, `aw_add_service_executable()`, `aw_add_kernel_driver()`.
* **Ecosystem conventions:** `.clang-format`, `.clang-tidy`, `.editorconfig`, `docs/CPP_GUIDELINES.md` — standardized across `ai-warevo`.
* **Working out of the box:** Builds, passes `ctest`, and runs sanitizers immediately after bootstrap.
* **Starter skeletons:** Every archetype includes `.in` template files for quick project generation.
```

#### Updated Project Layout

```markdown
## 🗂️ Project Layout

```
├── archetypes/                  # CMake archetype helpers (template-owned)
│   ├── CMakeLists.txt           # Aggregator for all archetype .cmake files
│   ├── 01_core.cmake            # aw_add_header_only_library, aw_add_static_library
│   ├── 02_shared_plugin.cmake   # aw_add_shared_library, aw_add_plugin_module
│   ├── 03_modules.cmake         # aw_add_cxx_module_library
│   ├── 04_executables.cmake     # aw_add_executable, aw_add_gui_executable
│   ├── 05_service.cmake         # aw_add_service_executable
│   ├── 06_kernel.cmake          # aw_add_kernel_driver
│   └── skeletons/               # Starter template files for each archetype
│       ├── header_only/
│       ├── static/
│       ├── shared/
│       ├── plugin/
│       ├── module/
│       ├── cli/
│       ├── gui/
│       ├── service/
│       └── kernel/
├── cmake/                       # Shared CMake infrastructure (template-owned)
│   └── AwProjectDefaults.cmake
├── docs/                        # Project documentation
│   └── CPP_GUIDELINES.md        # Shared coding conventions (template-owned)
├── include/aw/template_cpp/     # Public headers
│   ├── hello.hpp
│   └── detail/
├── src/                         # Implementation (.cpp files)
│   └── hello.cpp
├── tests/                       # Catch2 v3 unit tests
├── examples/                    # Example applications
├── tools/                       # (empty placeholder)
├── todo/                        # Task roadmap for AI sessions
├── .clang-format                # Code formatting rules (template-owned)
├── .clang-tidy                  # Static analysis rules (template-owned)
├── .editorconfig                # Editor configuration (template-owned)
├── .github/workflows/           # CI/CD workflows (template-owned)
├── CMakeLists.txt               # Project targets (project-owned)
├── Makefile                     # Build shortcuts (project-owned)
├── CLAUDE.md                    # AI agent guidance (project-owned)
├── README.md                    # User-facing documentation (project-owned)
├── CHANGELOG.md                 # Keep a Changelog (project-owned)
├── VERSION                      # Single source of truth (project-owned)
└── LICENSE                      # MIT License (project-owned)
```

**Template-owned files** (updated via `git pull template main`): `cmake/`, `archetypes/`, `docs/CPP_GUIDELINES.md`, `.clang-format`, `.clang-tidy`, `.editorconfig`, `.gitattributes`, `.gitignore`, `.github/workflows/`, `Makefile`.

**Project-owned files** (touched once on init): `CMakeLists.txt`, `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `VERSION`, `LICENSE`, `include/`, `src/`, `tests/`, `examples/`, `tools/`, `todo/`.
```

#### Updated CMake Options Table

```markdown
## 🔧 CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `AW_<PROJECT>_WARNINGS_AS_ERRORS` | `OFF` | Build with `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Werror` |
| `AW_<PROJECT>_BUILD_EXAMPLES` | `ON` (top-level) | Build `examples/` subdirectory |
| `AW_<PROJECT>_BUILD_TESTS` | `ON` (top-level) | Build `tests/` subdirectory |
| `AW_<PROJECT>_ENABLE_COVERAGE` | `OFF` | Enable gcov / lcov code coverage instrumentation |
| `AW_<PROJECT>_SANITIZE` | `none` | Sanitizer: `none`, `address` (ASan+UBSan), or `thread` (TSan) |
| `AW_<PROJECT>_INSTALL` | `ON` (top-level) | Generate install rules and CMake package config |
| `AW_<PROJECT>_CXX_STANDARD` | `20` | C++ standard version: `20` or `23` |
```

#### New Section: Available Archetypes

```markdown
## 🏗️ Available Archetypes

| Archetype | CMake Helper | Description |
|-----------|-------------|-------------|
| **Header-Only Library** | `aw_add_header_only_library()` | INTERFACE target with `FILE_SET HEADERS` — zero-link, header-only utilities. |
| **Static Library** | `aw_add_static_library()` | STATIC target with `FILE_SET HEADERS` — default active target, safest for shared libraries. |
| **Shared Library** | `aw_add_shared_library()` | SHARED target with cross-platform `AW_API` visibility macros, DllMain / constructor support. |
| **Plugin Module** | `aw_add_plugin_module()` | MODULE target with `extern "C"` factory entry point — runtime-loaded plugins. |
| **C++20 Module** | `aw_add_cxx_module_library()` | CMake 3.28+ `FILE_SET CXX_MODULES` — modern module-based compilation. |
| **CLI Executable** | `aw_add_executable()` | Standard console executable with argument parsing skeleton. |
| **GUI Executable** | `aw_add_gui_executable()` | Win32 GUI subsystem, macOS `.app` bundle, Linux binary with desktop integration. |
| **System Service** | `aw_add_service_executable()` | Windows SCM service + POSIX daemon with `systemd` integration. |
| **Kernel Driver** | `aw_add_kernel_driver()` | Windows WDK `.sys` + Linux `.ko` Kbuild — kernel-mode drivers. |

See `archetypes/skeletons/README.md` for detailed usage examples.
```

### 3. Create `archetypes/skeletons/README.md`

```markdown
# 📦 Archetype Skeletons

This directory contains starter template files (`.in` extension) for each C++ archetype.

## How to Use

1. **Copy** the relevant `.in` files to your project.
2. **Replace** `@PLACEHOLDERS@` with your project-specific values (e.g., `@PROJECT_NAME@`, `@NAMESPACE@`).
3. **Remove** the `.in` extension.
4. **Customize** the code to match your needs.

## Skeleton Index

### Header-Only Library (`header_only/`)
| File | Description |
|------|-------------|
| `example.hpp.in` | Header-only public API header |
| `CMakeLists.txt.example` | How to call `aw_add_header_only_library()` |

### Static Library (`static/`)
| File | Description |
|------|-------------|
| `example_lib.hpp.in` | Static library public header |
| `example_lib.cpp.in` | Static library implementation |
| `tests/test_example.cpp.in` | Catch2 test file |
| `CMakeLists.txt.example` | How to call `aw_add_static_library()` |

### Shared Library (`shared/`)
| File | Description |
|------|-------------|
| `export_macro.hpp.in` | Cross-platform `AW_API` visibility macro |
| `tests/test_plugin.cpp.in` | Catch2 test for shared library |
| `CMakeLists.txt.example` | How to call `aw_add_shared_library()` |

### Plugin Module (`plugin/`)
| File | Description |
|------|-------------|
| `plugin_interface.hpp.in` | Abstract plugin interface (IPlugin) |
| `CMakeLists.txt.example` | How to call `aw_add_plugin_module()` |

### C++20 Module (`module/`)
| File | Description |
|------|-------------|
| `ModuleCard.cppm.in` | C++20 module implementation unit |
| `ModuleCard.hin.in` | C++20 module interface unit |
| `tests/test_module.cpp.in` | Catch2 test that imports the module |
| `CMakeLists.txt.example` | How to call `aw_add_cxx_module_library()` |
| `COMPATIBILITY.md` | Compiler compatibility notes |

### CLI Executable (`cli/`)
| File | Description |
|------|-------------|
| `main.cpp.in` | CLI `main()` with argument parsing |

### GUI Executable (`gui/`)
| File | Description |
|------|-------------|
| `win32/main.cpp.in` | Win32 `WinMain` entry point |
| `win32/resource.h.in` | Win32 resource header |
| `win32/icon.rc.in` | Win32 resource script |
| `macos/AppDelegate.swift.in` | macOS SwiftUI app delegate |
| `macos/Info.plist.in` | macOS Info.plist |
| `linux/main.cpp.in` | Linux GUI executable |
| `linux/app.desktop.in` | Linux desktop entry |
| `linux/icons/symbolic.svg.in` | Linux app icon |
| `CMakeLists.txt.example` | How to call `aw_add_gui_executable()` |

### System Service (`service/`)
| File | Description |
|------|-------------|
| `windows/service.cpp.in` | Windows SCM `ServiceMain` |
| `windows/service.h.in` | Windows service header |
| `windows/install_service.bat.in` | Windows install/uninstall script |
| `posix/daemon.cpp.in` | POSIX daemon with `SIGTERM`/`SIGINT` |
| `posix/daemon.h.in` | POSIX daemon header |
| `posix/myapp.service.in` | systemd `.service` unit file |
| `posix/CMakeLists.txt.example` | How to call `aw_add_service_executable()` |

### Kernel Driver (`kernel/`)
| File | Description |
|------|-------------|
| `windows/driver.cpp.in` | Windows WDK `DriverEntry` |
| `windows/driver.h.in` | Windows WDK driver header |
| `windows/CMakeLists.txt.example` | How to call `aw_add_kernel_driver()` (Windows) |
| `linux/module.c.in` | Linux kernel module (`init`/`exit`) |
| `linux/Kbuild.in` | Linux Kbuild file |
| `linux/Makefile.in` | Legacy Makefile alternative |
| `linux/CMakeLists.txt.example` | How to call `aw_add_kernel_driver()` (Linux) |
| `README_KERNEL.md` | Kernel-mode development guidelines |
```

## Acceptance Criteria

1. **`docs/CPP_GUIDELINES.md` updated**: Contains new sections 12 (ABI/Visibility), 13 (Kernel-Mode Constraints), and 14 (C++20 Module Guidelines).
2. **`README.md` updated**: Documents all 9 archetypes, CMake helpers, 4-step `git pull template main` workflow, and updated project layout.
3. **`archetypes/skeletons/README.md` created**: Index of all skeleton templates with descriptions and links.
4. **All archetype helpers documented**: Each `aw_add_*` function is listed with its signature and description.
5. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes.
6. **No broken links**: All internal references (markdown links) resolve correctly.
