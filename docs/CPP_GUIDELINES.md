# C++20/23 Coding Conventions — ai-warevo Ecosystem

This document codifies the shared C++ coding standards across all `ai-warevo` repositories.
AI agents and human contributors **must** follow these rules.

## 1. C++ Standard & Language Features

- Target **C++20** minimum; C++23 is permitted where it adds clear value.
- Prefer **concepts / `requires`** over SFINAE:
  ```cpp
  template <typename Func>
      requires std::invocable<Func>
  auto call(Func fn) -> std::invoke_result_t<Func>;
  ```
- Use `if constexpr`, `std::jthread` / `std::stop_token`, `std::binary_semaphore`, RAII everywhere.
- No raw `new` / `delete`; use `std::make_unique`, `std::make_shared`, or value semantics.
- No manual `lock` / `unlock` — use `std::lock_guard`, `std::scoped_lock`.

## 2. Naming Conventions

| Entity | Convention | Example |
| --- | --- | --- |
| Types (classes, structs, enums, concepts) | `PascalCase` | `Task<T>`, `ThreadPool` |
| Functions, variables, files, namespaces | `snake_case` | `cancel_after()`, `aw::tpl` |
| Private data members | `trailing_underscore_` | `state_` |
| `detail` namespace members | bare (no prefix) | `mtx_` is fine |
| Namespace | lowercase | `aw::tpl::threading` |
| Exceptions | `PascalCase` + `Exception` suffix | `OperationCanceledException` |

Exceptions derive from `std` exceptions and carry a default message matching the .NET-style naming where applicable.

## 3. Formatting (`.clang-format`)

- **4 spaces**, **120 column** limit.
- **Attached braces** (`BreakBeforeBraces: Attach`).
- `Type* p` / `Type& r` (pointer alignment: left).
- `public:` flush with `class` (`AccessModifierOffset: -4`).
- **No indentation inside namespaces** (`NamespaceIndentation: None`).
- Closing namespace comment: `} // namespace aw::tpl`.
- Constructor initializer lists break **before** `:`.
- `template <typename T>` / `requires ...` each on their own line.
- Short `if (x) stmt;` and one-line inline accessors are fine.
- `SortIncludes: Never`, `IncludeBlocks: Preserve` — keep hand-grouped includes (own header, `aw/`, then `<std>`).

## 4. Header Structure

```cpp
#pragma once

/**
 * @file example.hpp
 * @brief Brief one-line description.
 */

// 1. Own header
#include <aw/<project>/example.hpp>

// 2. ai-warevo headers
#include <aw/<project>/other.hpp>

// 3. Standard library (blank line between groups)

#include <string>
#include <memory>

namespace aw::project {
// ...
} // namespace aw::project
```

- Headers start with `#pragma once`.
- A `.cpp` includes its own header **first**.
- Include groups separated by blank lines.
- In tests: Catch2 header first, then own header, then `aw/`, then `<std>`.

## 5. Documentation

### Doxygen

- **Every public class, function, concept, constructor and exception type** gets a `/** ... */` block.
- Tags: `@class`/`@struct`, `@brief`, `@tparam`, `@param[in]`, `@return`, `@throws`, `@c`.
- State thread-safety / lifetime guarantees where relevant.
- Brief `/** */` on `detail/` types is encouraged.

### Inline Comments

- **Minimal**: use only for non-obvious logic, subtle concurrency/lifetime/ordering reasons, or the *why* behind a choice.
- Never narrate what the code obviously does (`// increment counter`).
- Prefer better names over comments.
- Use `///` only for one-line member docs.

## 6. API Design

- `[[nodiscard]]` on return types that carry state or results (e.g. `Task`, pure getters/factories).
- `noexcept` where truly non-throwing.
- `explicit` on single-arg constructors.
- Delete copy constructors where ownership is unique.
- Keep the public surface **small and boring**: no new dependencies, no macros in public headers.
- Mirror .NET equivalents where applicable; state the .NET equivalent in Doxygen (`@c Task.X`).

## 7. Concurrency & Lifetime

- **Never block on a pool worker.** `.result()` / `.wait()` on an unfinished task from a pool thread throws `std::logic_error`.
- Inside coroutines use `co_await`; block only on non-pool threads (`main`).
- **Don't invoke capturing coroutine lambdas as temporaries** (CP.51):
  - Pass state as parameters: `[](int& x) -> Task<void> { ... }(x)`
  - Or use `Task<>::run([&] { ... })`
  - Or keep the lambda alive in a named variable.
- Shared state guarded by mutexes with explicit ordering rationale in a short comment.
- Thread destruction order: declare threads **last** so they are joined first.
- Deterministic test concurrency: use latches, atomics, `std::binary_semaphore` — **not sleeps as synchronization**.

## 8. Testing Discipline

- Every new feature, edge case, error path and branch gets a test. **No untested code.**
- Tag tests with areas: `TEST_CASE("name", "[area]")`.
- CI requires **>90% line coverage**.
- Tests must pass under ASan / UBSan / TSan.
- Tests have a 120 s ctest timeout (deadlock fails, not hangs).
- Cover failure modes: exceptions through `co_await`, cancellation before/during/after, moved-from objects.

## 9. Project Layout

Namespaces map 1:1 to directories. Internal helpers live in `detail/` next to the owning namespace.

```
include/aw/<project>/          # public headers
src/<project>/                 # .cpp files mirroring header tree
tests/                         # Catch2 test sources
examples/                      # 01_*.cpp, 02_*.cpp …
docs/                          # project-specific docs
cmake/                         # AwProjectDefaults.cmake
```

- Dependencies flow **bottom-up** (e.g. `tasks` → `threading` → root; never the reverse).
- `detail/` never depends on public convenience headers.

## 10. Changelog & Releases

- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com) and SemVer.
- Every user-visible change adds a bullet under `## [Unreleased]` in the same commit.
- Categories: `Breaking`, `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- Version bump derived from categories: `Breaking`/`Removed` → major, `Added`/`Deprecated` → minor, `Fixed`/`Changed`/`Security` → patch.
- `VERSION` file is the single source of truth — never hard-code version in CMake.
- Use `scripts/release.sh` / `scripts/release.ps1` / `make release` to cut releases.

## 11. Tooling (Optional, Not in CI)

| Tool | Purpose | Usage |
| --- | --- | --- |
| `.clang-format` | Code formatting | `clang-format -i <file>` (format only files you touch) |
| `.clang-tidy` | Static analysis | `clang-tidy -p build/dev <file>` |
| `.editorconfig` | Editor basics | Any editor that reads `.editorconfig` |
| `compile_commands.json` | clangd / IDE | Set by `CMAKE_EXPORT_COMPILE_COMMANDS=ON` (top-level only) |

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

See `examples/archetypes/skeletons/kernel/linux/` for kernel driver source examples.

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

See `examples/archetypes/skeletons/` for module skeleton examples and compatibility notes.
