# ⚡ aw::template_cpp

> **A production-grade C++20 project template.**
> Pick one of 9 ready-made archetypes and start coding in minutes.

[![CI](https://github.com/ai-warevo/template-cpp/actions/workflows/ci.yml/badge.svg)](https://github.com/ai-warevo/template-cpp/actions/workflows/ci.yml)
[![Tests & Coverage](https://github.com/ai-warevo/template-cpp/actions/workflows/test.yml/badge.svg)](https://github.com/ai-warevo/template-cpp/actions/workflows/test.yml)
[![coverage](https://raw.githubusercontent.com/ai-warevo/template-cpp/badges/coverage.svg)](https://ai-warevo.github.io/template-cpp/htmlcov/)

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

One command scaffolds your entire project:

```sh
make init-<archetype> PROJECT=<name>
```

| Command | What it does |
|---------|--------------|
| `make init-list` | Show all available archetypes |
| `make init-static PROJECT=my_lib` | Scaffold a static library |
| `make init-shared PROJECT=my_app` | Scaffold a shared library / DLL |
| `make init-header-only PROJECT=my_utils` | Scaffold a header-only library |
| `make init-plugin PROJECT=my_plugin` | Scaffold a plugin module |
| `make init-module PROJECT=my_mod` | Scaffold a C++20 module |
| `make init-cli PROJECT=my_cli` | Scaffold a CLI executable |
| `make init-gui PROJECT=my_gui` | Scaffold a GUI executable |
| `make init-service PROJECT=my_svc` | Scaffold a system service / daemon |
| `make init-kernel PROJECT=my_drv` | Scaffold a kernel driver |

This copies a complete project structure from `examples/<archetype>/` into your directory, replaces all placeholder names with your project name, and generates a `Makefile`. **Existing files are never overwritten.**

### Step 3: Build and test

```sh
# Build
make build

# Run tests
make test

# Or with CMake directly
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

**That's it.** Your project builds and tests pass.

---

## What's in the repo?

```
docs/                ← Coding conventions (.clang-format, .clang-tidy, etc.)
examples/            ← Archetype templates + shared cmake/ infrastructure
scripts/             ← Utility scripts (release automation)
```

Each directory under `examples/<archetype>/` is a **complete, self-contained project** with `CMakeLists.txt`, `src/`, `include/`, `tests/`, and `examples/`. When you run `make init-<archetype>`, that entire structure plus the shared `cmake/AwProjectDefaults.cmake` from `examples/cmake/` is copied to your directory.

The `cmake/` directory (one shared file) is **template-owned** — embedded in `examples/cmake/`. Everything else is **project-owned** — you edit these freely.

---

## Updating the template

When the template evolves (new archetypes, bug fixes, better conventions), you can pull updates without conflicts:

```sh
# Add the template remote (one-time)
git remote add template https://github.com/ai-warevo/template-cpp.git

# Pull updates — no conflicts guaranteed
git pull template main

# Rebuild and test
make build && make test
```

The separation between template-owned (`cmake/AwProjectDefaults.cmake` in `examples/cmake/`) and project-owned (`CMakeLists.txt`, `src/`, `include/`) means your code never conflicts with template updates.

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

---

## License

MIT. See [`LICENSE`](LICENSE).
