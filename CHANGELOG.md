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

- `make init TYPE=<type> [NAME=] [NS=] [TESTS=0] [DRY=1]`: pure-Bash project generator (`templates/scaffold.sh`) with `cli`, `static` and `dynamic` templates, `@@KEY@@` placeholders, type aliases and name inference.
- `make list`, `make eject`, `make selftest`, and shared `CMakePresets.json`.

### Changed

- Replaced the old archetype-based `make init ARCHETYPE=... PROJECT=...` with the generator above.

## [0.1.0] - 2026-11-14

### Added

- First release of the `template-cpp` repository.

[Unreleased]: https://github.com/ai-warevo/template-cpp/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ai-warevo/template-cpp/releases/tag/v0.1.0
