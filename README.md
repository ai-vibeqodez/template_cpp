# ⚡ aw::template_cpp

[![C++20](https://img.shields.io/badge/C++-%2300599C.svg?logo=c%2B%2B&logoColor=white)](https://cppreference.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **A production-grade C++20 project template.**
> Pick one of 9 ready-made archetypes and start coding in minutes.

---

## What is this?

This is a **project starter kit** for C++20/23. You clone it, pick an **archetype** (a project type), and you get:

- A working `CMakeLists.txt` — builds immediately
- Tests (Catch2 v3), examples, and install rules
- Sanitizers (ASan/TSan), code coverage, warnings-as-errors
- `.clang-format`, `.clang-tidy`, `.editorconfig` — consistent style
- A release workflow (SemVer, CHANGELOG, GitHub Actions)

**You do not need to configure anything.** Just clone, pick a template, and go.

---

## 9 Archetypes — pick your project type

| # | Archetype | When to use it |
|---|-----------|----------------|
| 1 | **Header-only library** | Your library is all inline / templates — no `.cpp` files needed. |
| 2 | **Static library** *(default)* | A regular library linked into your executables. Safe, simple, no DLL headaches. |
| 3 | **Shared library** | A DLL / `.so` / `.dylib` that other programs load at runtime. |
| 4 | **Plugin module** | A dynamically-loaded plugin with an `extern "C"` factory. |
| 5 | **C++20 module** | You want to use `import` / `export module` (requires CMake 3.28+). |
| 6 | **CLI executable** | A command-line tool with argument parsing. |
| 7 | **GUI executable** | A desktop app — Win32, macOS `.app`, or Linux with `.desktop`. |
| 8 | **System service** | A Windows SCM service or a Linux systemd daemon. |
| 9 | **Kernel driver** | A Windows `.sys` driver or Linux `.ko` kernel module. |

**Not sure which one?** Pick **2 — Static library** (it's the default). You can always change it later.

---

## Quick start

### Step 1: Clone and initialise

```sh
# Clone this template
git clone https://github.com/ai-warevo/template-cpp.git my-project
cd my-project

# Remove the template remote — your repo is now independent
git remote remove template

# (Optional) Add your own remote
git remote add origin git@github.com:your-org/my-project.git
git push -u origin main
```

### Step 2: Pick an archetype

Open `CMakeLists.txt`. You'll see this line:

```cmake
aw_add_static_library(${PROJECT_NAME}
    SOURCES src/hello.cpp
    HEADERS include/aw/template_cpp/hello.hpp
    LINK_LIBRARIES Threads::Threads
)
```

That's the **static library** archetype. To switch to another archetype:

1. **Replace** `aw_add_static_library(...)` with the helper for your chosen archetype (see the table below).
2. **Copy** the skeleton files from `archetypes/skeletons/<archetype>/` into your project directories.
3. **Rename** the skeleton files to match your project.

Here are the helpers:

| Archetype | CMake call | Skeletons directory |
|-----------|-----------|---------------------|
| Header-only | `aw_add_header_only_library(TARGET my_lib HEADERS include/aw/my_lib/my_lib.hpp)` | `skeletons/header_only/` |
| Static library | `aw_add_static_library(TARGET my_lib SOURCES src/my_lib.cpp HEADERS include/aw/my_lib/my_lib.hpp)` | `skeletons/static/` |
| Shared library | `aw_add_shared_library(TARGET my_lib SOURCES src/my_lib.cpp HEADERS include/aw/my_lib/my_lib.hpp)` | `skeletons/shared/` |
| Plugin module | `aw_add_plugin_module(TARGET my_plugin SOURCES src/my_plugin.cpp)` | `skeletons/plugin/` |
| C++20 module | `aw_add_cxx_module_library(TARGET my_mod MODULES src/my_mod.cppm HEADERS include/aw/my_mod/my_mod.hin)` | `skeletons/module/` |
| CLI executable | `aw_add_executable(TARGET my_cli SOURCES src/main.cpp)` | `skeletons/cli/` |
| GUI executable | `aw_add_gui_executable(TARGET my_gui SOURCES src/main.cpp)` | `skeletons/gui/` |
| System service | `aw_add_service_executable(TARGET my_svc SOURCES src/service.cpp)` | `skeletons/service/` |
| Kernel driver | `aw_add_kernel_driver(TARGET my_drv SOURCES src/driver.c PLATFORM linux)` | `skeletons/kernel/` |

### Step 3: Build and test

```sh
# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel

# Run tests
ctest --test-dir build --output-on-failure

# Or use the Makefile
make build
make test
```

**That's it.** Your project builds and tests pass.

---

## What's in the repo?

```
archetypes/          ← CMake helpers (aw_add_* functions) — don't edit
skeletons/           ← Starter templates — copy into your project
cmake/               ← Shared build infrastructure — don't edit
docs/                ← Coding conventions (.clang-format, etc.)
include/             ← Your public headers
src/                 ← Your implementation (.cpp files)
tests/               ← Your unit tests
examples/            ← Example applications
```

**The rule:** `archetypes/` and `cmake/` are **template-owned** — you update them by pulling from the template repo. Everything else (`include/`, `src/`, `tests/`, `examples/`) is **project-owned** — you edit these freely.

---

## Updating the template

When the template evolves (new archetypes, bug fixes, better conventions), you can pull updates without conflicts:

```sh
# Add the template remote (one-time)
git remote add template https://github.com/ai-warevo/template-cpp.git

# Pull updates — no conflicts guaranteed
git pull template main

# Rebuild and test
cmake -B build && cmake --build build && ctest --test-dir build
```

The separation between template-owned (`archetypes/`, `cmake/`) and project-owned (`CMakeLists.txt`, `src/`, `include/`) means your code never conflicts with template updates.

---

## CMake options

| Option | Default | What it does |
|--------|---------|-------------|
| `AW_<PROJECT>_BUILD_TESTS` | `ON` | Build unit tests |
| `AW_<PROJECT>_BUILD_EXAMPLES` | `ON` | Build example apps |
| `AW_<PROJECT>_INSTALL` | `ON` | Generate install rules |
| `AW_<PROJECT>_SANITIZE` | `none` | `none`, `address`, or `thread` |
| `AW_<PROJECT>_ENABLE_COVERAGE` | `OFF` | Enable gcov / lcov |
| `AW_<PROJECT>_CXX_STANDARD` | `20` | `20` or `23` |

---

## Makefile shortcuts

| Command | What it does |
|---------|-------------|
| `make build` | Configure + build (Debug) |
| `make test` | Build + run ctest |
| `make lint` | Run clang-tidy |
| `make format` | Run clang-format |
| `make clean` | Remove build/ |
| `make release` | Cut a SemVer release |

---

## License

MIT. See [`LICENSE`](LICENSE).
