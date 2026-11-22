# CXX23Runtime.cmake — C++23 coroutine/format runtime support check
#
# Check that the selected C++ toolchain provides C++23 standard library features
# required by modern C++ libraries (coroutines, format, std::jthread, etc.).
#
# Usage:
#   include(CXX23Runtime)
#   aw_check_cxx23_runtime()
#
# Must be called after project() and find_package(Threads).
# Sets AW_HAS_CXX23_RUNTIME to indicate availability.

include(CheckCXXSourceCompiles)

function(aw_check_cxx23_runtime)
    set(CMAKE_REQUIRED_FLAGS "")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(CMAKE_REQUIRED_FLAGS "-std=c++23")
    endif()

    # Propagate -stdlib=libc++ to the compile check (CMAKE_CXX_FLAGS is not
    # automatically picked up by check_cxx_source_compiles).
    if(CMAKE_CXX_FLAGS MATCHES "-stdlib=libc\\+\\+")
        list(APPEND CMAKE_REQUIRED_FLAGS "-stdlib=libc++")
    endif()

    if(TARGET Threads::Threads)
        list(APPEND CMAKE_REQUIRED_LIBRARIES Threads::Threads)
    endif()

    # libc++ in Clang ≤ 18 does not provide <format> yet — only check
    # <coroutine> which is the feature actually used by modern coroutine libraries.
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_FLAGS MATCHES "-stdlib=libc\\+\\+")
        set(_COROUTINE_TEST "
            #include <coroutine>
            int main() { return 0; }
        ")
    else()
        set(_COROUTINE_TEST "
            #include <coroutine>
            #include <format>
            int main() {
                std::format(\"{}\", 42);
                return 0;
            }
        ")
    endif()

    check_cxx_source_compiles("${_COROUTINE_TEST}" AW_HAS_CXX23_RUNTIME)

    if(NOT AW_HAS_CXX23_RUNTIME)
        message(FATAL_ERROR
            "The selected C++ toolchain lacks the C++23 standard library features "
            "(coroutine, format) required for modern C++23 libraries. "
            "Try a newer GCC (≥13), Clang (≥17), or MSVC (≥19.35)."
        )
    endif()
endfunction()
