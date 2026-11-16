cmake_minimum_required(VERSION 3.21)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(cmake/ProjectConfig)
aw_project_config(NAME @@NAME@@ NS @@NS@@)
project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)

# Core logic lives in a library so the tests can link it; main.cpp stays trivial.
include(cmake/CoreLibrary)
aw_core_library(NAME @@NAME@@ ID @@NAME_ID@@)

add_executable(@@NAME@@ src/main.cpp)
target_link_libraries(@@NAME@@ PRIVATE @@NS@@::@@NAME@@_core)
target_compile_options(@@NAME@@ PRIVATE ${AW_WARNINGS})

# Tests exist only if the project was generated with tests (the tests/ directory is optional).
include(cmake/Tests)
aw_setup_tests()
