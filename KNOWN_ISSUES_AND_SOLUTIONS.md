# Known Issues and Solutions - template_cpp Generator

**Last Updated**: 2026-11-22  
**Category**: Generator workflow and dependency management

## Issues Encountered with gitsync C++23 Rewrite

### Issue #1: **In-Place Generation Not Recommended**

**Problem**:
When generating in the template_cpp directory itself:
```bash
cd template_cpp
make init TYPE=cli NAME=gitsync
# [generates CMakeLists.txt, src/, include/, tests/ in template_cpp root]
# User must then manually move files to separate directory
# Requires cleanup with `make eject`
```

**Root Cause**: The generator was designed to work in its own directory, but it's inconvenient for creating standalone projects.

**Solution**: Always use the `OUT=` parameter:
```bash
# RECOMMENDED: Generate to external directory
make -C template_cpp init TYPE=cli NAME=gitsync OUT=../gitsync-new
cd gitsync-new
make build
make test
```

**Why It's Better**:
- ✅ Project is isolated and ready immediately
- ✅ No manual file movement required
- ✅ No need to run `make eject`
- ✅ template_cpp directory stays clean
- ✅ Can run multiple `make init` without conflicts

---

### Issue #2: **FetchContent Network Timeouts**

**Problem**:
When generating or building projects, nlohmann/json and spdlog downloads can timeout:
```
CMake Error: Failed to clone repository: 'https://github.com/nlohmann/json.git'
CMake Error: Head sha can't be blank
```

**Root Cause**: Network latency or repository access issues during `FetchContent_MakeAvailable()`.

**Solutions**:

#### Solution 2A: Pre-download dependencies locally
```bash
# In your project, add a wrapper script (before CMake):
#!/bin/bash
mkdir -p external/nlohmann
wget -q https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp \
  -O external/nlohmann/json.hpp

# Then add to CMakeLists.txt:
add_library(nlohmann_json INTERFACE)
target_include_directories(nlohmann_json INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/external)
```

#### Solution 2B: Use system package manager
```bash
# On Ubuntu/Debian:
sudo apt-get install nlohmann-json3-dev libspdlog-dev catch2

# Then use find_package():
find_package(nlohmann_json REQUIRED)
find_package(spdlog REQUIRED)
find_package(Catch2 REQUIRED)
```

#### Solution 2C: Increase timeout and retries
```cmake
# In CMakeLists.txt:
set(FETCHCONTENT_TRY_FIND_PACKAGE_MODE BOTH)
set(FETCHCONTENT_QUIET OFF)

FetchContent_Declare(
    nlohmann_json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.3
    GIT_SHALLOW ON
    TIMEOUT 180)  # 3 minutes instead of default 60 seconds
```

#### Solution 2D: Use GitHub releases directly (fastest)
```cmake
# Single-header json download (no git clone):
FetchContent_Declare(
    nlohmann_json
    URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp
    DOWNLOAD_NO_EXTRACT ON
    TIMEOUT 60)
```

**Recommended for template_cpp**: Update the generated `CMakeLists.txt` to use **Solution 2D** for json (single-header), and add **Solution 2C** timeout for spdlog.

---

### Issue #3: **Configuration Files Not Copied to Generated Projects**

**Problem**: Generated projects didn't include `.clang-format`, `.clang-tidy`, `.editorconfig`.

**Status**: ✅ **ALREADY FIXED IN template_cpp**

The generator **already copies** these files via the `SHARED_FILES` variable in `scaffold.sh`:
```bash
SHARED_FILES=".clang-format .clang-tidy .editorconfig .gitignore .gitattributes CMakePresets.json VERSION"
```

**However**: Users need to know that:
1. These files must exist in template_cpp root
2. They are copied AS-IS (not templated)
3. They should be committed to version control

**Recommendation**: Add to README:
```markdown
### Configuration Files

The generator copies these configuration files to all projects:
- `.clang-format` - Code style (don't gitignore this!)
- `.clang-tidy` - Static analysis settings
- `.editorconfig` - Editor configuration
- `.gitignore` - Git ignore rules
- `.gitattributes` - Git line endings
- `CMakePresets.json` - CMake build presets
- `VERSION` - Project version

These are **shared configuration** and should be committed to version control.
```

---

### Issue #4: **.gitignore Incorrectly Gitignores Config Files**

**Problem**: Generated projects' `.gitignore` included `.clang-tidy` as a build artifact:
```gitignore
# WRONG - should not be here:
.clang-tidy          # This is a config file!
.clang-format        # This is a config file!
```

**Solution**: `.gitignore` should only exclude build artifacts:
```gitignore
# CORRECT:
build/                    # Build output
_deps/                    # CMake dependencies
.clangd/                  # Clang-tools cache (NOT .clang-tidy!)
*.o *.a *.so *.dylib      # Object files
CMakeCache.txt            # CMake cache
compile_commands.json     # Build metadata
```

**Recommendation**: Update template `.gitignore`:
```bash
# In templates/*/files/.gitignore or root .gitignore:
# Keep this comment to prevent accidental gitignore of config files:
# NOTE: .clang-format, .clang-tidy, .editorconfig are version-controlled config files
# Only gitignore build artifacts and cache:

build/
_deps/
.clangd/
*.o
*.a
*.so
*.dylib
CMakeCache.txt
compile_commands.json
```

---

### Issue #5: **CMakeLists.txt aw_core_library() Auto-discovery Complexity**

**Problem**: The `aw_core_library()` macro's auto-discovery of source files caused:
1. User confusion about which files get compiled
2. Need to explicitly list sources for clarity
3. Linking errors when sources weren't found

**Solution**: Make sources explicit in generated CMakeLists.txt:
```cmake
# CURRENT (implicit - requires sources to match pattern):
aw_core_library(NAME gitsync ID gitsync)

# RECOMMENDED (explicit - clear what's compiled):
aw_core_library(
    NAME gitsync 
    ID gitsync
    SOURCES
        src/config_settings.cpp
        src/config_reader.cpp
        src/main.cpp)

target_link_libraries(gitsync_core PUBLIC nlohmann_json spdlog::spdlog)
```

**Recommendation**: Update `templates/*/files/CMakeLists.txt` to explicitly list sources.

---

### Issue #6: **Build Preset Template Not Always Available**

**Problem**: Generated projects could fail to build if CMakePresets.json wasn't compatible with the system.

**Solution**: Enhance CMakePresets.json with platform detection:
```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "default",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "clang18",
      "inherits": "default",
      "cacheVariables": {
        "CMAKE_CXX_COMPILER": "clang++-18"
      },
      "condition": {
        "type": "inList",
        "string": "${hostSystemName}",
        "list": ["Linux", "Darwin"]
      }
    },
    {
      "name": "msvc",
      "inherits": "default",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
      }
    }
  ]
}
```

---

## Recommendations for template_cpp Updates

### 1. Update README.md Quick Start
```markdown
## Recommended Workflow

### For Creating a New Project

**Method 1: Direct generation to external directory** (RECOMMENDED)
```bash
# Generate project in a new directory, not in template_cpp:
make -C template_cpp init TYPE=cli NAME=myapp OUT=../myapp
cd ../myapp
make build
make test
```

**Method 2: Clone, generate, then eject** (If you need to modify templates)
```bash
git clone https://github.com/ai-warevo/template_cpp.git myapp
cd myapp
make init TYPE=cli
# ... (customize project) ...
make eject  # Remove generator once done
```
```

### 2. Add Troubleshooting Section
Create `TROUBLESHOOTING.md`:
```markdown
# Troubleshooting

## CMake FetchContent Timeout

**Problem**: `CMake Error: Failed to clone repository`

**Solutions** (in order of preference):
1. Use pre-downloaded headers (see docs)
2. Increase timeout: `TIMEOUT 180`
3. Use GitHub releases directly instead of git clone
4. Install from system package manager

## Build Fails with Clang Not Found

Use the MSVC preset on Windows or install clang:
```bash
make build  # Uses platform defaults
# or
cmake --preset msvc  # Windows
cmake --preset default  # Linux/macOS without clang
```

## Tests Don't Build

Ensure Catch2 is available:
```bash
# Option 1: Use FetchContent (default, slow)
# Option 2: Install system package
sudo apt-get install catch2
```
```

### 3. Create BEST_PRACTICES.md
```markdown
# Best Practices for C++23 Projects with template_cpp

## 1. Always use OUT= for new projects
```bash
make -C template_cpp init TYPE=cli NAME=myapp OUT=../myapp
```

## 2. Version control these files
```
.clang-format
.clang-tidy
.editorconfig
CMakePresets.json
CMakeLists.txt
Makefile
VERSION
```

## 3. Don't gitignore config files
Keep `.clang-format`, `.clang-tidy` in git - they're version-controlled config.

## 4. Handle dependencies explicitly
```cmake
# BAD: Rely on auto-discovery
aw_core_library(NAME foo)

# GOOD: Explicit sources
aw_core_library(
    NAME foo
    SOURCES src/main.cpp src/helper.cpp)
```

## 5. Use FetchContent wisely
For header-only: Use direct download
For compiled: Use find_package() first, FetchContent as fallback
```

---

## Action Items for template_cpp

- [ ] Update `CMakePresets.json` template with platform conditions
- [ ] Update `.gitignore` template with clarifying comments
- [ ] Add `FetchContent TIMEOUT` to `CMakeLists.txt` templates
- [ ] Create `TROUBLESHOOTING.md` in template_cpp root
- [ ] Create `BEST_PRACTICES.md` in template_cpp root
- [ ] Update main `README.md` Quick Start section with `OUT=` emphasis
- [ ] Add note: "Config files (.clang-format, .clang-tidy) are version-controlled"
- [ ] Consider using URL-based FetchContent for json header

---

## For ai-warevo-cpp-init Skill

Update the skill to:
1. ✅ Always use `OUT=` parameter pointing to target directory
2. ✅ Generate outside template_cpp directory
3. ✅ Document timeout handling for FetchContent
4. ✅ Provide fallback methods if network fails
5. ✅ Explain which files should be gitignored
6. ✅ Make sources explicit in CMakeLists.txt

---

## Summary

| Issue | Severity | Status | Action |
|-------|----------|--------|--------|
| In-place generation | Medium | Docs | Add `OUT=` examples |
| FetchContent timeout | High | Impl | Use direct download for json |
| Config files handling | Low | ✅ Works | Add clarifying comments |
| .gitignore config files | Medium | Docs | Add comment to template |
| Explicit sources needed | Medium | Docs | Update templates |
| Build preset compatibility | Low | Impl | Add platform conditions |

All issues are **solvable with documentation updates** and **minor CMakeLists.txt template changes**.
