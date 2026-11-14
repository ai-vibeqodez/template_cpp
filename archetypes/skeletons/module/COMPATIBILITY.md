# C++20 Module Compiler Compatibility

| Compiler | Version | Support Level | Flags |
|----------|---------|---------------|-------|
| **GCC** | 13+ | Partial (TS-based) | `-fmodules-ts` |
| **GCC** | 14+ | Improved | `-fmodules-ts` |
| **Clang** | 15+ | Partial (TS-based) | `-fmodules-ts` |
| **Clang** | 17+ | Improved | `-fmodules-ts` |
| **MSVC** | 19.37+ | Limited (`/experimental:module`) | `/std:c++20 /experimental:module` |
| **MSVC** | 19.40+ | Better | `/std:c++latest /experimental:module` |

## Important Notes

1. **CMake 3.28+ required** for `FILE_SET CXX_MODULES`.
2. **Modules are not yet a C++20 standard feature** in most compilers — they use the C++ Modules TS.
3. **Module interface units** (`.hin` / `.cppm` with `export module`) define the public API.
4. **Module implementation units** (`.cppm` with `module`) contain the implementation.
5. **Consumers** use `import ModuleName;` instead of `#include`.
6. **Header units** (`import "header.h";`) are a C++23 feature supported in Clang 15+ and MSVC 19.37+.
7. **Build system complexity**: modules change the compilation model significantly — precompiled modules, module dependencies, and incremental build support vary by compiler.
8. **Recommendation**: Use modules for performance-critical libraries where the build system supports them. Fall back to traditional headers for maximum compatibility.
