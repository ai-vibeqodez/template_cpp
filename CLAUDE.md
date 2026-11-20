# CLAUDE.md

Guidance for working on this project.
Read `README.md` for the user-facing API; this file is about *how to change the repo*.

## Project-specific architecture

This repo is a `dotnet new`-style C++23 project generator. The root stays clean: `CMakeLists.txt`, `src/`, `include/` and `tests/`
exist only in a generated project (the template files live under `templates/<type>/files/`).

### Layout and ownership

- `Makefile`: a thin wrapper. It exports command-line `TYPE/NAME/NS/TESTS/DRY` as `AW_*` environment variables (no shell quoting
  needed for `NS=aw::foo`) and calls `templates/scaffold.sh` (`OUT=` becomes `AW_OUT`; `--out` cannot be passed through make). It also holds the everyday `build/test/lint/format/clean` targets.
- `templates/scaffold.sh`: the **only** generator code (`list | init | eject`). Pure Bash 3.2+. It has no per-template logic.
- `templates/selftest.sh`: generates every template, builds it and runs ctest, plus generator checks.
- `templates/<type>/template.conf`: sourced in a subshell. Only `DESCRIPTION` and `ALIASES` (space-separated) are read.
- `templates/<type>/files/`: mirrors the project root. Its top-level entries must be in `MANAGED` in `scaffold.sh`
  (`CMakeLists.txt src include tests examples`); `init` replaces exactly those on every run (`examples/` only if the template produces it).
- `SHARED_FILES` in `scaffold.sh` lists files/dirs copied as-is from the repository root into the generated project:
  `cmake scripts .clang-format .clang-tidy .editorconfig .gitignore .gitattributes CMakePresets.json VERSION`.
  These are not rendered (no `@@KEY@@` processing).
- There is **no** `templates/_common/`.
- `scripts/` is for project-level scripts only (`release.sh`, `release.ps1`). Never put generator code there.

### Placeholders

`@@KEY@@`, replaced in contents *and* in file/directory names. Keys are defined by `KEYS` in `scaffold.sh`:
`NAME NAME_ID NAME_UPPER NS NS_OPEN NS_CLOSE NS_PATH NS_UPPER MACRO_PREFIX TYPE`
(example values are in `README.md`). Any `@@[A-Z0-9_]+@@` left after rendering aborts the run with file and line.
To add a key, add it to `KEYS`, set `P_<KEY>` in `cmd_init`, and document it in `README.md`. Do not use `@@..@@` for anything else in templates.

### Rules for adding a template

1. Copy the closest template: `cp -r templates/static templates/<type>`.
2. Write `template.conf` (`DESCRIPTION`, `ALIASES`). Aliases must not collide with other types or aliases.
3. Keep it self-contained, with no cross-template includes. Duplication between templates is intentional.
4. Put tests in `files/tests/` (own `CMakeLists.txt`, Catch2 v3 via `FetchContent`). Do not reference `tests/` from other places except
   the root `CMakeLists.txt` guard `EXISTS tests/CMakeLists.txt`, which makes `TESTS=0` work.
5. Use `@@NS_OPEN@@`/`@@NS_CLOSE@@`, `@@NS_PATH@@` for the include dir, and `@@NAME_ID@@` for file stems.
6. Run `make selftest`. It auto-discovers the new template. Update the template table in `README.md`.

### Generator invariants

- Pure Bash 3.2 (macOS) and Git Bash: no associative arrays, `mapfile`, `${v^^}`, or `sed -i`. No Python.
- Render into a staging dir, then move into place, so failed validation never leaves a half-generated project.
- Re-running `init` overwrites the managed paths unconditionally (with a warning). That is the specified behaviour; do not add a refusal.
- `eject` removes `templates/` only. The Makefile's generator targets then fail with a clear message.
- Templates and scripts are LF-only (`.gitattributes`).

## Changelog & releases

Add every user-visible change under `## [Unreleased]` in `CHANGELOG.md` in the same commit that makes it.
`scripts/release.sh` / `scripts/release.ps1` derive the next version from its categories.
