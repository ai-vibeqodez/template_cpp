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
* **Shared CMake infrastructure:** `cmake/AwProjectDefaults.cmake` provides sanitizers (ASan/TSan), code coverage, warnings-as-errors, and `FetchContent`-aware target export — all automatically disabled when consumed as a dependency.
* **Ecosystem conventions:** `.clang-format`, `.clang-tidy`, `.editorconfig`, `docs/CPP_GUIDELINES.md` — standardized across `ai-warevo`.
* **Working out of the box:** Builds, passes `ctest`, and runs sanitizers immediately after bootstrap.

## 🚀 Quick Start

### Bootstrap a new project

```sh
# 1. Clone this template (shallow, keeps history)
git clone --depth 1 https://github.com/ai-warevo/template-cpp.git my-project
cd my-project

# 2. Remove the template remote and re-initialize
git remote remove template
git init

# 3. Add your own remote (optional, for now)
git remote add origin git@github.com:your-org/my-project.git
```

The repository is now yours. **Do not modify** `cmake/AwProjectDefaults.cmake`, `.clang-format`, `.clang-tidy`, `.editorconfig`, `.gitattributes`, `.gitignore`, or `.github/workflows/ci.yml` — these are managed by the template.

### Pull future template updates

```sh
# Add the template remote (one-time, if you removed it)
git remote add template https://github.com/ai-warevo/template-cpp.git

# Pull template updates — no merge conflicts guaranteed
git pull template main
```

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
| --- | --- | --- |
| `AW_TEMPLATE_CPP_WARNINGS_AS_ERRORS` | `OFF` | Build with `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Werror` |
| `AW_TEMPLATE_CPP_BUILD_EXAMPLES` | `ON` (top-level) | Build `examples/` subdirectory |
| `AW_TEMPLATE_CPP_BUILD_TESTS` | `ON` (top-level) | Build `tests/` subdirectory |
| `AW_TEMPLATE_CPP_ENABLE_COVERAGE` | `OFF` | Enable gcov / lcov code coverage instrumentation |
| `AW_TEMPLATE_CPP_SANITIZE` | `none` | Sanitizer: `none`, `address` (ASan+UBSan), or `thread` (TSan) |
| `AW_TEMPLATE_CPP_INSTALL` | `ON` (top-level) | Generate install rules and CMake package config |

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
├── cmake/                   # Shared CMake infrastructure (template-owned)
│   └── AwProjectDefaults.cmake
├── docs/                    # Project documentation
│   └── CPP_GUIDELINES.md    # Shared coding conventions (template-owned)
├── include/aw/template_cpp/ # Public headers
│   ├── hello.hpp            # Umbrella / main header
│   └── detail/              # Internal implementation details
├── src/                     # Implementation (.cpp files)
│   └── hello.cpp
├── tests/                   # Catch2 v3 unit tests
├── examples/                # Example applications
├── tools/                   # (empty placeholder)
├── todo/                    # (empty placeholder)
├── .clang-format            # Code formatting rules (template-owned)
├── .clang-tidy              # Static analysis rules (template-owned)
├── .editorconfig            # Editor configuration (template-owned)
├── .github/workflows/       # CI/CD workflows (template-owned)
├── CMakeLists.txt           # Project targets (project-owned)
├── Makefile                 # Build shortcuts (project-owned)
├── CLAUDE.md                # AI agent guidance (project-owned)
├── README.md                # User-facing documentation (project-owned)
├── CHANGELOG.md             # Keep a Changelog (project-owned)
├── VERSION                  # Single source of truth (project-owned)
└── LICENSE                  # MIT License (project-owned)
```

**Template-owned files** (updated via `git pull template main`): `cmake/`, `docs/CPP_GUIDELINES.md`, `.clang-format`, `.clang-tidy`, `.editorconfig`, `.gitattributes`, `.gitignore`, `.github/workflows/`, `Makefile`.

**Project-owned files** (touched once on init): `CMakeLists.txt`, `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `VERSION`, `LICENSE`, `include/`, `src/`, `tests/`, `examples/`, `tools/`, `todo/`.

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.
