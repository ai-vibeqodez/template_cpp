# ── template-cpp: C++20/23 project archetype templates ────────────────
#
# Usage (from this repo):
#   make init-list              — list available archetypes
#   make init-<archetype> PROJECT=<name>
#       Copies examples/<archetype>/ to the current directory,
#       replaces __PROJECT__ placeholders with your project name.
#
# Usage (after init, in a generated project):
#   make build                   — configure + build
#   make test                    — build + run tests
#   make lint                    — run clang-tidy (if available)
#   make format                  — run clang-format (if available)
#   make clean                   — remove build/

BUILD_TYPE ?= Debug
BUILD_DIR  ?= build

.PHONY: build test lint format clean init-list \
        init init-header_only init-static init-shared init-plugin \
        init-module init-cli init-gui init-service init-kernel

# ── Build targets (for generated projects) ───────────────────────────
build:
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
	cmake --build $(BUILD_DIR) --config $(BUILD_TYPE) --parallel

test: build
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
	    -DAW__PROJECT_UPPER___BUILD_TESTS=ON \
	    -DAW__PROJECT_UPPER___BUILD_EXAMPLES=OFF
	cmake --build $(BUILD_DIR) --config $(BUILD_TYPE) --parallel
	ctest --test-dir $(BUILD_DIR) -C $(BUILD_TYPE) --output-on-failure

lint:
	@if command -v clang-tidy >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' 2>/dev/null | \
	        xargs clang-tidy -p $(BUILD_DIR) -- \
	            -std=c++20 -I include || true; \
	else \
	    echo "clang-tidy not found; install clang-tidy"; \
	fi

format:
	@if command -v clang-format >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' 2>/dev/null | \
	        xargs clang-format -i || true; \
	else \
	    echo "clang-format not found; install clang-format >= 15"; \
	fi

clean:
	rm -rf $(BUILD_DIR)

# ── Archetype scaffolding ────────────────────────────────────────────
# Usage: make init-<archetype> PROJECT=<name>
#   Copies examples/<archetype>/ → current directory
#   Replaces __PROJECT__ / __PROJECT_NAME__ / __PROJECT_UPPER__ /
#   __ProjectCamel__ / __MODULE_NAME__ placeholders

init-list:
	@echo "Available archetypes:"
	@for a in header_only static shared plugin module cli gui service kernel; do echo "  $$a"; done
	@echo ""
	@echo "Usage: make init-<archetype> PROJECT=<name>"
	@echo "  e.g. make init-static PROJECT=my_app"

init: init-list

init-header_only init-static init-shared init-plugin init-module init-cli init-gui init-service init-kernel:
	@if [ -z "$(PROJECT)" ]; then \
	    echo "ERROR: PROJECT not set."; \
	    echo "Usage: make $@ PROJECT=<name>"; \
	    exit 1; \
	fi
	@ARCHETYPE="$@"; \
	ARCHETYPE="$${ARCHETYPE#init-}"; \
	PROJ_LOWER="$(echo "$(PROJECT)" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"; \
	PROJ_UPPER="$(echo "$(PROJECT)" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"; \
	PROJ_CAMEL="$(echo "$(PROJECT)" | sed -E 's/(^|-)([a-z])/\U\2/g')"; \
	echo "==> Archetype : $$ARCHETYPE"; \
	echo "==> Project   : $(PROJECT) ($$PROJ_LOWER / $$PROJ_UPPER / $$PROJ_CAMEL)"; \
	echo ""; \
	echo "==> Copying examples/$$ARCHETYPE/ to current directory..."; \
	cp -r examples/$$ARCHETYPE/. .; \
	echo "==> Replacing __PROJECT__ placeholders..."; \
	find . -name '*.hpp' -o -name '*.cpp' -o -name '*.h' -o -name '*.cppm' -o -name '*.c' -o -name '*.txt' -o -name '*.in' -o -name '*.bat' -o -name '*.service' -o -name '*.desktop' -o -name '*.plist' -o -name '*.swift' -o -name '*.rc' -o -name 'Kbuild' -o -name '*.svg' | \
	    while read -r f; do \
	        sed -i \
	            -e "s|__PROJECT__|$$PROJ_LOWER|g" \
	            -e "s|__PROJECT_NAME__|$$PROJ_LOWER|g" \
	            -e "s|__PROJECT_UPPER__|$$PROJ_UPPER|g" \
	            -e "s|__ProjectCamel__|$$PROJ_CAMEL|g" \
	            -e "s|__MODULE_NAME__|$$PROJ_LOWER|g" \
	            "$$f"; \
	    done; \
	echo "==> Copying Makefile..."; \
	PROJ_UPPER_MK="$(echo "$(PROJECT)" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"; \
	sed "s|__PROJECT_UPPER__|$$PROJ_UPPER_MK|g" examples/_Makefile > Makefile; \
	rm examples/_Makefile; \
	echo "==> Done."; \
	echo ""; \
	echo "Structure:"; \
	find . -not -path './.git/*' -not -path './examples/*' -not -path './build/*' -not -path './.github/*' -not -path './archetypes/*' -not -name 'Makefile' -not -name 'VERSION' -not -name '.gitignore' -not -name '.clang-*' -not -name '.editorconfig' -not -name '.gitattributes' -not -name 'CHANGELOG*' -not -name 'CLAUDE*' -not -name 'LICENSE' -not -name 'NC_PREFIX' -not -name 'README*' | sort
