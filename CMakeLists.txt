# This is a placeholder CMakeLists.txt for template_cpp.
# The actual CMakeLists.txt files are in templates/<type>/files/
# This file is needed because FetchContent may try to build this repository
# when it's fetched as a dependency. We keep it minimal to avoid conflicts.

cmake_minimum_required(VERSION 3.23)
project(template_cpp_cmake_modules)

# Just provide the cmake/ directory; don't build anything
