cmake_minimum_required(VERSION 3.21)
project(@@NAME@@ VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(MSVC)
    set(AW_WARNINGS /W4)
else()
    set(AW_WARNINGS -Wall -Wextra -Wpedantic)
endif()

# Core logic lives in a library so the tests can link it; main.cpp stays trivial.
add_library(@@NAME@@_core STATIC src/@@NAME_ID@@.cpp)
add_library(@@NS@@::@@NAME@@_core ALIAS @@NAME@@_core)
target_include_directories(@@NAME@@_core PUBLIC include)
target_compile_features(@@NAME@@_core PUBLIC cxx_std_20)
target_compile_options(@@NAME@@_core PRIVATE ${AW_WARNINGS})

add_executable(@@NAME@@ src/main.cpp)
target_link_libraries(@@NAME@@ PRIVATE @@NS@@::@@NAME@@_core)
target_compile_options(@@NAME@@ PRIVATE ${AW_WARNINGS})

# Tests exist only if the project was generated with tests (the tests/ directory is optional).
if(PROJECT_IS_TOP_LEVEL AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
    include(CTest)
    if(BUILD_TESTING)
        add_subdirectory(tests)
    endif()
endif()
