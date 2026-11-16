cmake_minimum_required(VERSION 3.21)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(cmake/ProjectConfig)
aw_project_config(NAME @@NAME@@ NS @@NS@@)
project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)

add_library(@@NAME@@ STATIC src/@@NAME_ID@@.cpp)
add_library(@@NS@@::@@NAME@@ ALIAS @@NAME@@)
target_include_directories(@@NAME@@ PUBLIC include)
target_compile_features(@@NAME@@ PUBLIC cxx_std_20)
target_compile_options(@@NAME@@ PRIVATE ${AW_WARNINGS})

# Tests exist only if the project was generated with tests (the tests/ directory is optional).
include(cmake/Tests)
aw_setup_tests()
