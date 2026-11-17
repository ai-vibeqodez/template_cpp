# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Maintainer notes (see CLAUDE.md, "Changelog & releases"):
- Add every user-visible change under `## [Unreleased]` in the same commit that makes it.
- Categories: Breaking, Added, Changed, Deprecated, Removed, Fixed, Security. Omit empty ones.
- scripts/release.sh / scripts/release.ps1 derive the next version from those categories.
-->

## [Unreleased]

## [0.4.0] - 2026-11-17

### Added

- `make init … OUT=<dir>` (`AW_OUT`): generate into another directory. `examples/` is now a managed path.
- `static` template: `examples/` with a sample, `FILE_SET HEADERS`, install rules, the options `<NAME>_BUILD_TESTS`, `_BUILD_EXAMPLES`, `_INSTALL` and `_WARNINGS_AS_ERRORS`, and CMake 3.23 as the minimum.
- `aw_test_target(SOURCES …)` accepts several test sources (`TESTS_SOURCE` still works).
- `aw_install_library(DEPENDENCIES …)` writes `find_dependency()` calls into the package config; `NS` may be the full alias (`aw::tpl`).
- `clang18-libcxx` preset (`clang++-18 -stdlib=libc++`).

### Changed

- `static` template: the CMake alias is now `@@NS@@` (e.g. `aw::foo`) instead of `@@NS@@::@@NAME@@`; the tests, install and example targets follow. Tests/examples/install default to `OFF` when used as a subproject.

### Fixed

- `static` template: the include guard `#endif` now comes after the closing namespace.

## [0.3.0] - 2026-11-17

### Added

- read project VERSION from file instead of hardcoding
- `make init TYPE=<type> [NAME=] [NS=] [TESTS=0] [DRY=1]`: pure-Bash project generator (`templates/scaffold.sh`) with `cli`, `static` and `dynamic` templates, `@@KEY@@` placeholders, type aliases and name inference.
- `make list`, `make eject`, `make selftest`, and shared `CMakePresets.json`.

### Fixed

- move AW_WARNINGS setup after project() to fix MSVC build
- use basename for log file paths and add debug info
- print cmake output on build failure for debugging
- remove CMAKE_BUILD_TYPE from presets to silence MSVC warning
- use uname to detect Windows and skip CMAKE_BUILD_TYPE for MSVC
- remove CMAKE_BUILD_TYPE from preset to silence MSVC warning

### Changed

- use reusable cmake/ modules and scaffold.sh shared-file copy
- Replaced the old archetype-based `make init ARCHETYPE=... PROJECT=...` with the generator above.

## [0.2.0] - 2026-11-17

### Added

- `make init TYPE=<type> [NAME=] [NS=] [TESTS=0] [DRY=1]`: pure-Bash project generator (`templates/scaffold.sh`) with `cli`, `static` and `dynamic` templates, `@@KEY@@` placeholders, type aliases and name inference.
- `make list`, `make eject`, `make selftest`, and shared `CMakePresets.json`.

### Changed

- Replaced the old archetype-based `make init ARCHETYPE=... PROJECT=...` with the generator above.

## [0.1.0] - 2026-11-14

### Added

- First release of the `template_cpp` repository.

[Unreleased]: https://github.com/ai-warevo/template_cpp/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/ai-warevo/template_cpp/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/ai-warevo/template_cpp/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ai-warevo/template_cpp/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ai-warevo/template_cpp/releases/tag/v0.1.0
