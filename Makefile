# ── aw::template_cpp ─────────────────────────────────────────────────
# `dotnet new`-style generator + everyday build targets for the generated project.
#
#   make init TYPE=<type> [NAME=<name>] [NS=<namespace>] [OUT=<dir>] [TESTS=0] [DRY=1]
#   make list        list templates (and aliases)
#   make selftest    generate + build + test every template (needs cmake, a compiler, network for Catch2)
#   make eject       remove templates/ once you no longer need the generator
#
#   make build | test | lint | format | clean      (BUILD_TYPE=Debug|Release, default Debug)
#
#   make release [PUSH=1]        cut a SemVer release from CHANGELOG.md
#   make release-dry-run         preview the next version without changing anything
#   make changelog [FORCE=1]     update [Unreleased] from git log (conventional commits)
#   make changelog-dry-run       preview changelog update
#
# Examples:
#   make init TYPE=static NAME=my-lib NS=aw::foo
#   make init TYPE=cli                      # NAME inferred from this directory's name, NS=aw::unnamed
#   make init TYPE=lib TESTS=0              # alias for static, without tests/ and Catch2
#
# Values reach scaffold.sh through the environment (AW_*), so no shell quoting is needed for NS=aw::foo etc.

# Detect POSIX shell: MSYS2/MinGW/Cygwin/WSL all have /usr/bin.
# Only pure Windows (no /usr/bin) falls back to PowerShell.
IS_POSIX := $(strip $(if $(wildcard /usr/bin),1,))

SCAFFOLD := bash templates/scaffold.sh
PRESET   := $(if $(filter Release,$(BUILD_TYPE)),release,debug)

# Only honour variables given on the command line: NAME/TYPE often exist in the user's environment already.
ifeq ($(origin TYPE),command line)
export AW_TYPE := $(TYPE)
endif
ifeq ($(origin NAME),command line)
export AW_NAME := $(NAME)
endif
ifeq ($(origin NS),command line)
export AW_NS := $(NS)
endif
ifeq ($(origin TESTS),command line)
export AW_TESTS := $(TESTS)
endif
ifeq ($(origin OUT),command line)
export AW_OUT := $(OUT)
endif
ifeq ($(origin DRY),command line)
export AW_DRY := $(DRY)
endif

.DEFAULT_GOAL := help
.PHONY: help list init selftest eject build test lint format clean release release-dry-run changelog changelog-dry-run update

help:
	@echo "aw::template_cpp — C++23 project generator"
	@echo ""
	@echo "Generator:"
	@echo "  make init TYPE=<type> [NAME=<name>] [NS=<ns>] [OUT=<dir>] [TESTS=0] [DRY=1]"
	@echo "  make list        list templates"
	@echo "  make selftest    verify every template builds and passes its tests"
	@echo "  make eject       remove templates/"
	@echo ""
	@echo "Project:"
	@echo "  make build | test | lint | format | clean   (BUILD_TYPE=Release for release)"
	@echo ""
	@if [ -f templates/scaffold.sh ]; then $(SCAFFOLD) list; else echo "(templates/ has been ejected)"; fi

list init selftest:
	@if [ ! -f templates/scaffold.sh ]; then echo "error: templates/ not found (already ejected?)" >&2; exit 1; fi
	@$(if $(filter selftest,$@),bash templates/selftest.sh,$(SCAFFOLD) $@)

eject:
	@$(SCAFFOLD) eject

# ── release & changelog ──────────────────────────────────────────────
release:
ifneq ($(IS_POSIX),1)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/release.ps1 $(if $(PUSH),-Push)
else
	bash scripts/release.sh $(if $(PUSH),--push)
endif

release-dry-run:
ifneq ($(IS_POSIX),1)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/release.ps1 -DryRun
else
	bash scripts/release.sh --dry-run
endif

changelog:
ifneq ($(IS_POSIX),1)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/changelog-update.ps1 $(if $(FORCE),-Force)
else
	bash scripts/changelog-update.sh $(if $(FORCE),--force)
endif

changelog-dry-run:
ifneq ($(IS_POSIX),1)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/changelog-update.ps1 -DryRun
else
	bash scripts/changelog-update.sh --dry-run
endif

# Update all scripts from ai-warevo/.github.
update:
ifneq ($(IS_POSIX),1)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/updater.ps1
else
	bash scripts/updater.sh
endif

# ── project targets ──────────────────────────────────────────────────
build:
	cmake --preset $(PRESET)
	cmake --build --preset $(PRESET)

test: build
	@if [ -f tests/CMakeLists.txt ]; then ctest --preset $(PRESET); \
	else echo "No tests/ directory (generated with TESTS=0)."; fi

lint: build
	@if command -v clang-tidy >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' | xargs clang-tidy -p build/$(PRESET); \
	else echo "clang-tidy not found"; fi

format:
	@if command -v clang-format >/dev/null 2>&1; then \
	    find include src tests -name '*.hpp' -o -name '*.cpp' 2>/dev/null | xargs clang-format -i; \
	else echo "clang-format not found (>= 15 required)"; fi

clean:
	rm -rf build
