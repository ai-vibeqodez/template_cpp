# ⚡ aw::template_cpp

> **A minimal C++20 project generator, like `dotnet new`.**
> Pick a template, run one command, start coding.

[![CI](https://github.com/ai-warevo/template_cpp/actions/workflows/ci.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/ci.yml)
[![Tests & Coverage](https://github.com/ai-warevo/template_cpp/actions/workflows/test.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/test.yml)
[![coverage](https://raw.githubusercontent.com/ai-warevo/template_cpp/badges/coverage.svg)](https://ai-warevo.github.io/template_cpp/htmlcov/)

The repository root stays clean. `CMakeLists.txt`, `src/`, `include/` and `tests/` appear only after `make init`.
The generator is pure Bash (3.2+), so it runs on Linux, macOS and Windows Git Bash. It needs no Python.

## Quick start

```sh
git clone https://github.com/ai-warevo/template_cpp.git my-project
cd my-project

make list                                   # show templates
make init TYPE=static NAME=my-lib NS=aw::foo
make test                                   # configure + build + run tests
make eject                                  # optional: remove the generator (templates/)
```

Git for Windows does not ship `make`. Call the script directly instead:
`bash templates/scaffold.sh init static --name my-lib --ns aw::foo`.

## Templates

| `TYPE`    | Aliases               | Produces                                                         |
|-----------|-----------------------|------------------------------------------------------------------|
| `cli`     | `console`, `exe`, `app` | Executable: a small core library plus `main.cpp`               |
| `static`  | `lib`, `library`      | Static library with a public header                              |
| `dynamic` | `dll`, `so`, `shared` | Shared library with generated export macros (`GenerateExportHeader`) |

All templates are C++20 with `CXX_EXTENSIONS OFF`, strict warnings, and Catch2 v3 tests.

## `make init`

```sh
make init TYPE=<type> [NAME=<name>] [NS=<namespace>] [TESTS=0] [DRY=1]
```

| Option  | Default               | Meaning                                                                                              |
|---------|-----------------------|------------------------------------------------------------------------------------------------------|
| `TYPE`  | required              | Template name or alias.                                                                              |
| `NAME`  | current directory name | `[a-z][a-z0-9_-]*`. Not a C++ keyword and no `__`.                                                  |
| `NS`    | `aw::unnamed`         | C++ namespace, `::`-separated identifiers (e.g. `aw::foo::bar`).                                     |
| `TESTS` | `1`                   | `TESTS=0` skips `tests/` and the Catch2 `FetchContent` setup.                                        |
| `DRY`   | `0`                   | `DRY=1` prints the files that would be generated and writes nothing.                                 |

Re-running `make init` **overwrites** `CMakeLists.txt`, `src/`, `include/` and `tests/` without asking, and prints a warning that lists them.
Rendering happens in a staging directory first, so a validation error never leaves a half-generated project.

After a successful init you get a `make eject` hint. `make eject` removes `templates/` (the generator, its templates and its selftest).
The shared files stay in the repository root.

### Namespace example

`make init TYPE=static NAME=my-lib NS=aw::foo` generates:

```
CMakeLists.txt                    # add_library(my-lib ...) + alias aw::foo::my-lib
include/aw/foo/my_lib.hpp         # namespace aw::foo { ... }
src/my_lib.cpp
tests/CMakeLists.txt
tests/my_lib_tests.cpp
```

## Project targets

```sh
make build            # cmake --preset dev (Debug), or BUILD_TYPE=Release
make test
make lint             # clang-tidy (needs a build)
make format           # clang-format
make clean
```

These use [`CMakePresets.json`](CMakePresets.json) (`dev` = Debug, `release`). You can also call `cmake --preset dev` yourself.

## Layout

```
Makefile              thin wrapper: help, list, init, selftest, eject, build/test/lint/format/clean
CMakePresets.json     shared presets (dev, release)
.clang-format .clang-tidy .editorconfig .gitignore .gitattributes
scripts/              project-level scripts only (release.sh, release.ps1) — no generator code
templates/
  scaffold.sh         the generator: list | init | eject
  selftest.sh         generates, builds and tests every template
  <type>/
    template.conf     DESCRIPTION="..." and ALIASES="..."
    files/            mirrors the project root; rendered with @@KEY@@ placeholders
```

## Placeholders

`@@KEY@@` is replaced in file **contents** and in file and directory **names**.
Any `@@KEY@@` left unresolved fails the run and names the file and line.

| Key               | `NAME=my-lib NS=aw::foo`  | Typical use                                |
|-------------------|---------------------------|--------------------------------------------|
| `@@NAME@@`        | `my-lib`                  | CMake project and target names             |
| `@@NAME_ID@@`     | `my_lib`                  | File stems and C++ identifiers             |
| `@@NAME_UPPER@@`  | `MY_LIB`                  | Macros                                     |
| `@@NS@@`          | `aw::foo`                 | Qualified names, CMake alias namespace     |
| `@@NS_OPEN@@`     | `namespace aw::foo {`     | Opens the namespace                        |
| `@@NS_CLOSE@@`    | `} // namespace aw::foo`  | Closes the namespace                       |
| `@@NS_PATH@@`     | `aw/foo`                  | Include directory layout                   |
| `@@NS_UPPER@@`    | `AW_FOO`                  | Macro prefixes                             |
| `@@MACRO_PREFIX@@`| `AW_FOO_MY_LIB`           | Export macro, e.g. `AW_FOO_MY_LIB_API`     |
| `@@TYPE@@`        | `static`                  | Informational                              |

## Adding a template

1. `cp -r templates/static templates/<new-type>`.
2. Edit `template.conf` (`DESCRIPTION`, `ALIASES`) and the files under `files/`.
3. Run `make selftest`.

The script needs no edits, because templates are auto-discovered. See [`CLAUDE.md`](CLAUDE.md) for the rules.

## Verifying

`make selftest` generates each template into a temporary directory, then configures, builds and runs `ctest`.
It also checks validation errors, aliases, `--dry-run`, re-init, `--no-tests`, name inference and eject.
It needs `cmake`, a C++20 compiler, and network access for Catch2 (unless Catch2 v3 is installed).

## License

MIT. See [`LICENSE`](LICENSE).
