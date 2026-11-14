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

- Initial template: C++20 project scaffold with conflict-free `git pull template main` workflow.
- Shared CMake infrastructure (`cmake/AwProjectDefaults.cmake`): sanitizers, coverage, warnings-as-errors, install/export.
- Shared coding conventions (`docs/CPP_GUIDELINES.md`).
- Minimal working library (`aw::template_cpp`), Catch2 v3 test, and example.

## [0.1.0] - 2026-11-14

### Added

- First release of the `template-cpp` repository.

[Unreleased]: https://github.com/ai-warevo/template-cpp/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ai-warevo/template-cpp/releases/tag/v0.1.0
