#!/usr/bin/env bash
# Scaffold an archetype into the project.
# Usage: scripts/init-archetype.sh <archetype> <project_name>
#   e.g. bash scripts/init-archetype.sh shared my_app
#
# What it does:
#   1. Copies skeleton files from archetypes/skeletons/<archetype>/ into
#      src/, include/, tests/, examples/ — renaming to $PROJECT.
#   2. Replaces template markers: hello, HELLO, template_cpp, TEMPLATE_CPP.
#   3. Also replaces archetype-specific class names (e.g. Hello → $Project).
#   4. Never overwrites existing project files.

set -euo pipefail

ARCHETYPE="${1:?Usage: $0 <archetype> <project_name>}"
PROJECT="${2:?Usage: $0 <archetype> <project_name>}"

SKEL="archetypes/skeletons/${ARCHETYPE}"

if [ ! -d "$SKEL" ]; then
    echo "ERROR: archetype '${ARCHETYPE}' not found at ${SKEL}/"
    echo "Available: $(ls -1d archetypes/skeletons/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ' ')"
    exit 1
fi

# Derive naming variants
PROJ_LOWER="$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
PROJ_UPPER="$(echo "$PROJECT" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
PROJ_CAMEL="$(echo "$PROJECT" | sed -E 's/(^|-)([a-z])/\U\2/g')"

echo "==> Archetype : ${ARCHETYPE}"
echo "==> Project  : ${PROJECT} (${PROJ_LOWER} / ${PROJ_UPPER} / ${PROJ_CAMEL})"
echo ""

# All sed replacements — extend this list for each archetype
build_sed() {
    cat <<EOF
s/hello/${PROJ_LOWER}/g
s/hello_/${PROJ_LOWER}_/g
s/HELLO/${PROJ_UPPER}/g
s/template_cpp/${PROJ_LOWER}/g
s/TEMPLATE_CPP/${PROJ_UPPER}/g
s/Hello/${PROJ_CAMEL}/g
s/example_lib/${PROJ_LOWER}/g
s/ExampleLib/${PROJ_CAMEL}/g
s/plugin/${PROJ_LOWER}/g
s/Plugin/${PROJ_CAMEL}/g
s/ModuleCard/${PROJ_CAMEL}/g
s/myapp/${PROJ_LOWER}/g
s/MyApp/${PROJ_CAMEL}/g
EOF
}

SED_ARGS=()
while IFS= read -r line; do
    SED_ARGS+=(-e "$line")
done < <(build_sed)

# Replace template markers in a file and write to target
apply_template() {
    local src="$1"
    local target="$2"

    # Skip if target already exists (never overwrite user files)
    if [ -f "$target" ]; then
        echo "   SKIP  ${target} (already exists)"
        return
    fi

    mkdir -p "$(dirname "$target")"
    sed "${SED_ARGS[@]}" "$src" > "$target"

    echo "   created ${target}"
}

# Process a source directory into a destination directory
process_dir() {
    local src_dir="$1"
    local dest_dir="$2"

    [ -d "$src_dir" ] || return 0

    for src in "$src_dir"/*; do
        [ -f "$src" ] || continue
        local base
        base="$(basename "$src")"
        apply_template "$src" "${dest_dir}/${base}"
    done
}

# 1) Top-level skeletons → src/
process_dir "$SKEL" "src"

# 2) Platform-specific subdirectories
for subdir in linux windows macos win32 posix; do
    process_dir "${SKEL}/${subdir}" "src"
done

# 3) Header-only puts everything in include/
if [ "$ARCHETYPE" = "header_only" ]; then
    process_dir "$SKEL" "include/aw/${PROJ_LOWER}"
fi

# 4) Module archetype has a tests/ skeleton
if [ -d "${SKEL}/tests" ]; then
    process_dir "${SKEL}/tests" "tests"
fi

# 5) Replace old template files in tests/ and examples/ with archetype skeletons
#    This is the "migration" step — overwrites the default hello/example files.
migrate_tests() {
    local skel_tests="${SKEL}/tests"
    [ -d "$skel_tests" ] || return 0

    # Remove old default test files
    rm -f tests/test_hello.cpp tests/test_example.cpp

    for skel in "$skel_tests"/*; do
        [ -f "$skel" ] || continue
        local base
        base="$(basename "$skel")"
        # Remove .in extension for target name
        local target_name="${base%.in}"
        apply_template "$skel" "tests/${target_name}"
    done
}

migrate_examples() {
    local skel_examples="${SKEL}/examples"
    [ -d "$skel_examples" ] || return 0

    # Remove old default example files
    rm -f examples/01_hello.cpp examples/example_*.cpp

    for skel in "$skel_examples"/*; do
        [ -f "$skel" ] || continue
        local base
        base="$(basename "$skel")"
        local target_name="${base%.in}"
        apply_template "$skel" "examples/${target_name}"
    done
}

migrate_tests
migrate_examples

echo ""
echo "==> Done. Edit CMakeLists.txt to use the '${ARCHETYPE}' archetype helper."
