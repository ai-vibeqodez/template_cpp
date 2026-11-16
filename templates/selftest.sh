#!/usr/bin/env bash
# selftest.sh — generate every template into a temp dir, then configure, build and test it.
#   selftest.sh [TYPE...]     (default: all templates)
set -eu

TPL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$TPL_DIR")
SCAFFOLD="bash $TPL_DIR/scaffold.sh"
# Don't let a developer's AW_* environment leak into the checks.
unset AW_TYPE AW_NAME AW_NS AW_TESTS AW_DRY

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok   %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

command -v cmake >/dev/null 2>&1 || { echo "selftest: cmake not found" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/aw-selftest.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

# Fresh project dir with the shared root presets, like a real checkout.
newproj() { # DIRNAME
    mkdir -p "$WORK/$1"
    cp "$ROOT_DIR/CMakePresets.json" "$WORK/$1/"
    printf '%s' "$WORK/$1"
}

# Same as newproj but also copies VERSION (needed for CMake VERSION file read).
newproj_ver() { # DIRNAME
    mkdir -p "$WORK/$1"
    cp "$ROOT_DIR/CMakePresets.json" "$WORK/$1/"
    cp "$ROOT_DIR/VERSION" "$WORK/$1/"
    printf '%s' "$WORK/$1"
}
expect_fail() { # DESCRIPTION CMD...
    local d=$1; shift
    if "$@" >/dev/null 2>&1; then fail "$d (command unexpectedly succeeded)"; fi
    pass "$d"
}
build_and_test() { # DIR TESTS(1|0)
    # Windows CMake can't read MSYS paths such as /tmp/...; cygpath -m (Git Bash) fixes that.
    local d=$1
    if command -v cygpath >/dev/null 2>&1; then d=$(cygpath -m "$d"); fi
    # CMAKE_BUILD_TYPE is only needed for single-config generators (Ninja, Make).
    # Multi-config generators (Visual Studio, Xcode) ignore it and use the build preset's
    # "configuration" field instead.  Omit it on MSVC to avoid the CMake "unused-cli" warning.
    local extra_args=""
    local gen
    gen=$(cmake --system-information 2>/dev/null | grep "^Default Strategy" | sed 's/.*: //' || true)
    case "$gen" in
        *Visual*|*Xcode*) ;; # multi-config — nothing to add
        *) extra_args="-DCMAKE_BUILD_TYPE=Debug" ;; # single-config — need it
    esac
    (cd "$d" && cmake --preset dev $extra_args >/dev/null && cmake --build --preset dev >/dev/null) || fail "build failed in $1"
    if [ "$2" = 1 ]; then
        (cd "$d" && ctest --preset dev >/dev/null) || fail "tests failed in $1"
    fi
}

if [ $# -gt 0 ]; then TYPES="$*"; else TYPES=$($SCAFFOLD list | sed -n 's/^  \([^ ]*\) .*/\1/p'); fi
[ -n "$TYPES" ] || fail "no templates found"

section "generator checks"
d=$(newproj checks)
# shellcheck disable=SC2086
expect_fail "missing TYPE is rejected" $SCAFFOLD init --out "$d" --name x
# shellcheck disable=SC2086
expect_fail "unknown TYPE is rejected" $SCAFFOLD init nope --out "$d" --name x
# shellcheck disable=SC2086
expect_fail "bad NAME is rejected" $SCAFFOLD init static --out "$d" --name 'Bad Name'
# shellcheck disable=SC2086
expect_fail "keyword NAME is rejected" $SCAFFOLD init static --out "$d" --name class
# shellcheck disable=SC2086
expect_fail "bad NS is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::1bad'
# shellcheck disable=SC2086
expect_fail "keyword NS is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::new'
# shellcheck disable=SC2086
expect_fail "empty NS segment is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::::x'
# shellcheck disable=SC2086
$SCAFFOLD init lib --out "$d" --name x --dry-run | grep -q 'Template : static' || fail "alias lib -> static"
pass "alias lib resolves to static"
[ ! -e "$d/CMakeLists.txt" ] && [ ! -e "$d/src" ] || fail "dry run wrote files"
pass "dry run writes nothing"
# shellcheck disable=SC2010,SC2143
[ -z "$(ls -A "$d" | grep -v '^CMakePresets.json$')" ] || fail "dry run left stray files in output"

for t in $TYPES; do
    section "template: $t"
    d=$(newproj_ver "$t-hyphen")
    # shellcheck disable=SC2086
    $SCAFFOLD init "$t" --out "$d" --name my-lib --ns aw::foo::bar >/dev/null || fail "init $t failed"
    for p in CMakeLists.txt src include tests; do [ -e "$d/$p" ] || fail "$t: missing $p"; done
    [ -f "$d/include/aw/foo/bar/my_lib.hpp" ] || fail "$t: namespace/name path not rendered"
    grep -rq '@@' "$d/CMakeLists.txt" "$d/src" "$d/include" "$d/tests" && fail "$t: unresolved placeholder"
    grep -rq 'namespace aw::foo::bar {' "$d/include" || fail "$t: NS_OPEN not rendered"
    build_and_test "$d" 1
    pass "$t: init + build + ctest (NAME=my-lib NS=aw::foo::bar)"

    # Re-run over an existing project, without tests: must overwrite and drop tests/.
    # shellcheck disable=SC2086
    $SCAFFOLD init "$t" --out "$d" --name other --no-tests 2>"$WORK/warn.txt" >/dev/null || fail "$t: re-init failed"
    grep -q 'overwriting' "$WORK/warn.txt" || fail "$t: no overwrite warning"
    [ ! -e "$d/tests" ] || fail "$t: tests/ not removed with --no-tests"
    [ ! -e "$d/include/aw/foo" ] || fail "$t: stale files survived re-init"
    build_and_test "$d" 0
    pass "$t: re-init overwrites with warning; --no-tests builds"

    # Name inferred from the directory, default namespace.
    d=$(newproj_ver "infer-$t/Inferred.Dir")
    # shellcheck disable=SC2086
    $SCAFFOLD init "$t" --out "$d" >/dev/null || fail "$t: init with inferred name failed"
    [ -f "$d/include/aw/unnamed/inferred_dir.hpp" ] || fail "$t: NAME inference / default NS failed"
    pass "$t: NAME inferred from directory, NS defaults to aw::unnamed"
done

section "eject"
# Run eject on a copy so the real templates/ stays intact.
mkdir -p "$WORK/eject/templates"
cp "$TPL_DIR/scaffold.sh" "$WORK/eject/templates/"
bash "$WORK/eject/templates/scaffold.sh" eject >/dev/null || fail "eject failed"
[ ! -e "$WORK/eject/templates" ] || fail "eject left templates/"
pass "eject removes templates/"

printf '\nAll selftests passed.\n'
