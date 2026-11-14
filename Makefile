BUILD_TYPE = Debug
BASE_FLAGS = -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)

ifeq ($(OS),Windows_NT)
    PLATFORM = windows
    EXT = .exe
else
    PLATFORM = linux
    EXT =
endif

BUILD_DIR = build/$(PLATFORM)
BUILD_DIR_TEST = $(BUILD_DIR)/test
BUILD_DIR_DEMO = $(BUILD_DIR)/demo
ifeq ($(PLATFORM),windows)
    DEMO_DIR = ./$(BUILD_DIR_DEMO)/examples/$(BUILD_TYPE)
else
    DEMO_DIR = ./$(BUILD_DIR_DEMO)/examples
endif

.PHONY: build test lint format clean release release-dry-run
.PHONY: init init-list

# ── Build (default target) ───────────────────────────────────────────
build:
	cmake -B $(BUILD_DIR) --fresh $(BASE_FLAGS) \
	    -DAW_TEMPLATE_CPP_BUILD_TESTS=OFF \
	    -DAW_TEMPLATE_CPP_BUILD_EXAMPLES=OFF
	cmake --build $(BUILD_DIR) --config $(BUILD_TYPE) --parallel

# ── Run tests ────────────────────────────────────────────────────────
test:
	cmake -B $(BUILD_DIR_TEST) --fresh $(BASE_FLAGS) \
	    -DAW_TEMPLATE_CPP_BUILD_TESTS=ON \
	    -DAW_TEMPLATE_CPP_BUILD_EXAMPLES=OFF
	cmake --build $(BUILD_DIR_TEST) --config $(BUILD_TYPE) --parallel
	ctest --test-dir $(BUILD_DIR_TEST) -C $(BUILD_TYPE) --output-on-failure

# ── Run clang-tidy on changed files (top-level only) ─────────────────
lint:
	@if command -v clang-tidy >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' | \
	        xargs clang-tidy -p $(BUILD_DIR) -- \
	            -std=c++20 -I include || true; \
	else \
	    echo "clang-tidy not found; install it or configure with Ninja for compile_commands.json"; \
	fi

# ── Format with clang-format ─────────────────────────────────────────
format:
	@if command -v clang-format >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' | \
	        xargs clang-format -i; \
	else \
	    echo "clang-format not found; install clang-format >= 15"; \
	fi

# ── Clean build artifacts ────────────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR)

# ── Release (delegates to ai-warevo release scripts) ─────────────────
ifeq ($(PLATFORM),windows)
    RELEASE_CMD = powershell -NoProfile -ExecutionPolicy Bypass -File scripts/release.ps1
    RELEASE_PUSH = -Push
    RELEASE_DRY = -DryRun
else
    RELEASE_CMD = bash scripts/release.sh
    RELEASE_PUSH = --push
    RELEASE_DRY = --dry-run
endif

release:
	$(RELEASE_CMD) $(if $(PUSH),$(RELEASE_PUSH))

release-dry-run:
	$(RELEASE_CMD) $(RELEASE_DRY)

# ── Archetype scaffolding ────────────────────────────────────────────
# Usage: make init-<archetype> PROJECT=<name>
#   e.g. make init-shared PROJECT=my_app
#   Copies skeleton files from archetypes/skeletons/<archetype>/ into
#   include/, src/, tests/ and renames them to $PROJECT.
#   Existing project files are never overwritten.

init-list:
	@echo "Available archetypes:"
	@for a in header_only static shared plugin module cli gui service kernel; do echo "  $$a"; done
	@echo ""
	@echo "Usage: make init-<archetype> PROJECT=<name>"
	@echo "  e.g. make init-shared PROJECT=my_app"

init: init-list

init-header_only init-static init-shared init-plugin init-module init-cli init-gui init-service init-kernel:
	@if [ -z "$(PROJECT)" ]; then \
	    echo "ERROR: PROJECT not set."; \
	    echo "Usage: make $@ PROJECT=<name>"; \
	    exit 1; \
	fi
	@ARCHETYPE="$@"; \
	ARCHETYPE="$${ARCHETYPE#init-}"; \
	if [ "$(OS)" = "Windows_NT" ]; then \
	    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/init-archetype.ps1 -Archetype "$$ARCHETYPE" -Project "$(PROJECT)"; \
	else \
	    bash scripts/init-archetype.sh "$$ARCHETYPE" "$(PROJECT)"; \
	fi
