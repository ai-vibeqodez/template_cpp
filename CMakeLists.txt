cmake_minimum_required(VERSION 3.23)

# Single source of truth for the version; written by scripts/release.sh / release.ps1.
file(READ "${CMAKE_CURRENT_LIST_DIR}/VERSION" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
             "${CMAKE_CURRENT_LIST_DIR}/VERSION")

project(template_cpp VERSION ${PROJECT_VERSION} LANGUAGES CXX)

# ── Dependencies ─────────────────────────────────────────────────────
find_package(Threads REQUIRED)

# ── Include shared CMake infrastructure ──────────────────────────────
include(cmake/AwProjectDefaults.cmake)

# ── Set the project prefix for AwProjectDefaults ─────────────────────
set(AW_PROJECT_PREFIX "TEMPLATE_CPP")

# ── Library target ───────────────────────────────────────────────────
add_library(${PROJECT_NAME} STATIC
    src/hello.cpp
)
add_library(aw::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_20)
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

target_sources(${PROJECT_NAME}
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS include
        FILES
            include/aw/template_cpp/hello.hpp
)

target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads)

# Pass version as a compile definition so the library can report it.
target_compile_definitions(${PROJECT_NAME} PRIVATE
    TEMPLATE_CPP_VERSION="${PROJECT_VERSION}")

# ── Apply shared defaults ────────────────────────────────────────────
_aw_set_warnings(${PROJECT_NAME})
_aw_apply_sanitizers(${PROJECT_NAME})
_aw_apply_coverage(${PROJECT_NAME})
_aw_add_lint(${PROJECT_NAME})

# ── Install ──────────────────────────────────────────────────────────
_aw_setup_install(${PROJECT_NAME} ${PROJECT_NAME} "aw::" include)

# ── Examples (top-level only) ────────────────────────────────────────
option(AW_TEMPLATE_CPP_BUILD_EXAMPLES
       "Build aw::template_cpp example applications" ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})

if(AW_TEMPLATE_CPP_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# ── Tests (top-level only) ───────────────────────────────────────────
option(AW_TEMPLATE_CPP_BUILD_TESTS
       "Build aw::template_cpp unit tests" ${AW_TEMPLATE_CPP_IS_TOP_LEVEL})

if(AW_TEMPLATE_CPP_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
