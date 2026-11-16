include(FetchContent)

# Prefer an installed Catch2 v3; otherwise fetch it.
find_package(Catch2 3 QUIET)
if(NOT Catch2_FOUND)
    FetchContent_Declare(Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.7.1
        GIT_SHALLOW    TRUE)
    FetchContent_MakeAvailable(Catch2)
    list(APPEND CMAKE_MODULE_PATH "${catch2_SOURCE_DIR}/extras")
endif()
include(Catch)

add_executable(@@NAME@@_tests @@NAME_ID@@_tests.cpp)
target_link_libraries(@@NAME@@_tests PRIVATE @@NS@@::@@NAME@@ Catch2::Catch2WithMain)
target_compile_options(@@NAME@@_tests PRIVATE ${AW_WARNINGS})
catch_discover_tests(@@NAME@@_tests)
