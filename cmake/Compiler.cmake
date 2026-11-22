# Compiler.cmake — Unified C++23 compiler configuration
#
# Apply compiler-specific optimization flags, sanitization, and coverage instrumentation.
#
# Usage:
#   include(Compiler)
#   aw_configure_compiler(TARGET mylib [STRICT_WARNINGS])
#
# Applies:
#   - GCC < 11: -fcoroutines flag for coroutine support
#   - Clang + libc++: -fexperimental-library for std::jthread / std::stop_token
#   - STRICT_WARNINGS: convert warnings to errors (uses AW_STRICT_WARNINGS set by ProjectConfig)
#   - AW_ENABLE_COVERAGE: code coverage instrumentation
#   - AW_SANITIZE: address (ASan+UBSan) or thread (TSan) sanitizers

function(aw_configure_compiler)
    set(_oneValue TARGET)
    set(_options STRICT_WARNINGS)
    cmake_parse_arguments(_CFG "${_options}" "${_oneValue}" "" ${ARGN})

    if(NOT _CFG_TARGET)
        message(FATAL_ERROR "aw_configure_compiler() requires TARGET argument")
    endif()

    # Baseline warnings apply to every target built by the project. Strict
    # warnings are opt-in for the target that owns the policy option.
    if(DEFINED AW_WARNINGS AND NOT AW_WARNINGS STREQUAL "")
        target_compile_options(${_CFG_TARGET} PRIVATE ${AW_WARNINGS})
    endif()
    if(_CFG_STRICT_WARNINGS AND DEFINED AW_STRICT_WARNINGS AND NOT AW_STRICT_WARNINGS STREQUAL "")
        target_compile_options(${_CFG_TARGET} PRIVATE ${AW_STRICT_WARNINGS})
    endif()

    # Sanitizers (PUBLIC so consumers are also instrumented)
    if(DEFINED AW_SANITIZE AND NOT AW_SANITIZE STREQUAL "none")
        if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
            message(FATAL_ERROR "AW_SANITIZE requires GCC or Clang")
        endif()
        if(AW_ENABLE_COVERAGE)
            message(FATAL_ERROR "AW_SANITIZE and AW_ENABLE_COVERAGE cannot be used together")
        endif()

        if(AW_SANITIZE STREQUAL "address")
            set(_sanitize "address,undefined")
        elseif(AW_SANITIZE STREQUAL "thread")
            set(_sanitize "thread")
        else()
            message(FATAL_ERROR "AW_SANITIZE must be: none, address, or thread")
        endif()

        target_compile_options(${_CFG_TARGET} PUBLIC -fsanitize=${_sanitize} -fno-omit-frame-pointer -g)
        target_link_options(${_CFG_TARGET} PUBLIC -fsanitize=${_sanitize})
    endif()

    # Coverage instrumentation
    if(AW_ENABLE_COVERAGE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${_CFG_TARGET} PUBLIC --coverage -O0 -g -fprofile-update=atomic)
        target_link_options(${_CFG_TARGET} PUBLIC --coverage)
    endif()

    # GCC < 11 needs explicit -fcoroutines flag
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 11)
        target_compile_options(${_CFG_TARGET} PRIVATE -fcoroutines)
    endif()

    # Clang + libc++ needs experimental library support
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_FLAGS MATCHES "-stdlib=libc\\+\\+")
        target_compile_options(${_CFG_TARGET} PRIVATE -fexperimental-library)
    endif()
endfunction()
