# ⚡ aw::template_cpp

[![C++20](https://img.shields.io/badge/C++-%2300599C.svg?logo=c%2B%2B&logoColor=white)](https://cppreference.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<br />
[![CI](https://github.com/ai-warevo/template-cpp/actions/workflows/ci.yml/badge.svg)](https://github.com/ai-warevo/template-cpp/actions/workflows/ci.yml)
[![Tests & Coverage](https://github.com/ai-warevo/template-cpp/actions/workflows/test.yml/badge.svg)](https://github.com/ai-warevo/template-cpp/actions/workflows/test.yml)
<br />
[![Coverage](https://raw.githubusercontent.com/ai-warevo/template-cpp/refs/heads/badges/coverage.svg)](https://ai-warevo.github.io/template-cpp)

> **A production-grade C++20 project template for the [ai-warevo](https://github.com/ai-warevo) ecosystem.**
> *Designed for conflict-free manual `git pull template main` updates.* 🪄

`aw::template_cpp` is a minimal, clean C++20 library scaffold that demonstrates the shared build system, coding conventions, and release workflow used across all `ai-warevo` projects.

## ✨ Features

* **Conflict-free template updates:** Bootstrap once with `git clone --depth 1`, keep `template` as a remote, pull updates with `git pull template main` — no merge conflicts.
* **9 C++ archetypes:** Header-only, static, shared, plugin, C++20 modules, executables (CLI + GUI), system services, and kernel drivers.
* **Shared CMake infrastructure:** `cmake/AwProjectDefaults.cmake` provides sanitizers (ASan/TSan), code coverage, warnings-as-errors, and `FetchContent`-aware target export — all automatically disabled when consumed as a dependency.
* **CMake helper functions:** `aw_add_header_only_library()`, `aw_add_static_library()`, `aw_add_shared_library()`, `aw_add_plugin_module()`, `aw_add_cxx_module_library()`, `aw_add_executable()`, `aw_add_gui_executable()`, `aw_add_service_executable()`, `aw_add_kernel_driver()`.
* **Ecosystem conventions:** `.clang-format`, `.clang-tidy`, `.editorconfig`, `docs/CPP_GUIDELINES.md` — standardized across `ai-warevo`.
* **Working out of the box:** Builds, passes `ctest`, and runs sanitizers immediately after bootstrap.
* **Starter skeletons:** Every archetype includes `.in` template files for quick project generation.

## 🚀 Quick Start

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

### Build and test

```sh
# Quick build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel

# Run tests
cmake --build build --target test   # or: ctest --test-dir build --output-on-failure

# Or use the Makefile
make build
make test
```

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

See [`archetypes/skeletons/README.md`](archetypes/skeletons/README.md) for detailed usage examples.

## 📋 Makefile Commands

| Command | Description |
| --- | --- |
| `make build` | Configure and build the library (Debug) |
| `make test` | Configure, build, and run all tests with ctest |
| `make lint` | Run `clang-tidy` on `include/` and `src/` |
| `make format` | Run `clang-format -i` on all `.hpp` and `.cpp` files |
| `make clean` | Remove `build/` directory |
| `make release` | Cut a SemVer release from `CHANGELOG.md` [Unreleased] |
| `make release-dry-run` | Preview the release without committing |

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

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.
