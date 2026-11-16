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

[Unreleased]: https://github.com/ai-warevo/template_cpp/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ai-warevo/template_cpp/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ai-warevo/template_cpp/releases/tag/v0.1.0
