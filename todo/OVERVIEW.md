# 📋 template-cpp — Expansion Task Roadmap

Master progress tracker for the `template-cpp` expansion into a full-featured C++20/23 project archetype system.

## Task Checklist

| # | Task | Status | Dependencies | Summary |
|---|------|--------|--------------|---------|
| 01 | [Task 01: CMake Helpers & Structure](01_cmake_helpers_and_structure.md) | [x] | — | Refactor `AwProjectDefaults.cmake` and create `archetypes/` layout for conflict-free `git pull template main` |
| 02 | [Task 02: Header-Only & Static Libraries](02_header_only_and_static.md) | [x] | 01 | Implement `aw_add_header_only_library` (INTERFACE + FILE_SET HEADERS) and refine `aw_add_static_library` |
| 03 | [Task 03: Shared Library & Plugin Modules](03_shared_lib_and_plugin.md) | [x] | 01 | Implement `aw_add_shared_library` (cross-platform AW_API macros) and `aw_add_plugin_module` (MODULE target + extern "C" factory) |
| 04 | [Task 04: C++20 Modules](04_cxx20_modules.md) | [x] | 01 | Implement `aw_add_cxx_module_library` (CMake 3.28+ FILE_SET CXX_MODULES) with compiler compatibility notes |
| 05 | [Task 05: Executables & GUI](05_executables_and_gui.md) | [x] | 01 | Implement `aw_add_executable` (CLI) and `aw_add_gui_executable` (Win32 subsystem, macOS .app, Linux binary) |
| 06 | [Task 06: System Service & Daemon](06_system_service_daemon.md) | [ ] | 05 | Implement `aw_add_service_executable` (Windows SCM, POSIX daemon, systemd .service template) |
| 07 | [Task 07: Kernel Drivers](07_kernel_drivers.md) | [ ] | 01 | Implement `aw_add_kernel_driver` (Windows WDK .sys, Linux .ko Kbuild) |
| 08 | [Task 08: Docs & Guidelines](08_docs_and_guidelines.md) | [ ] | 01–07 | Update `CPP_GUIDELINES.md` and `README.md` with all archetypes, CMake helpers, and 4-step pull workflow |

## How AI Sessions Should Work

### Before Starting a Task

1. **Read this file** (`todo/OVERVIEW.md`) to understand the overall structure.
2. **Read the task file** (`todo/<N>_<task>.md`) for the specific task you are about to execute.
3. **Read `docs/CPP_GUIDELINES.md`** — all coding conventions must be followed.
4. **Read the current `cmake/AwProjectDefaults.cmake`** and `CMakeLists.txt` to understand the existing infrastructure.
5. **Verify dependencies**: only start a task when all its listed dependencies are marked `[x]` in this table.

### During Execution

1. Follow the **Implementation Details** section of the task file precisely.
2. Follow the **Files to Create/Modify** list — do not modify files outside this list unless explicitly required.
3. Adhere to all C++20/23 conventions from `docs/CPP_GUIDELINES.md` (naming, formatting, Doxygen, etc.).
4. All new CMake functions must use the `aw_` prefix and follow the existing naming pattern.
5. All new code must be placed under `archetypes/` (CMake helpers) or appropriate subdirectories (skeleton code).

### After Completing a Task

1. **Verify build**: run `cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build --parallel` and confirm zero errors.
2. **Verify tests**: run `ctest --test-dir build --output-on-failure` and confirm all tests pass.
3. **Sanity lint check**: if `clang-tidy` is available, run it on modified files.
4. **Update this file**: change the status from `[ ]` to `[x]` for the completed task.
5. **Commit cleanly**:
   ```sh
   git add -A
   git commit -m "feat(template-cpp): complete task 0N — <task-name>"
   ```
6. If the build or tests fail, fix the issue and re-verify before marking the task complete.

### Parallel Execution

Tasks that share no dependencies can be executed in parallel by different AI sessions. Currently:
- **Task 01** must complete first (foundation).
- **Tasks 02–07** all depend only on Task 01 and can theoretically run in parallel.
- **Task 08** must be last (depends on all others being complete).
