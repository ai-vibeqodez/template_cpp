include(FetchContent)

FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        v3.16.1
    GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(Catch2)

add_executable(aw_template_cpp_tests
    test_hello.cpp
)

target_link_libraries(aw_template_cpp_tests PRIVATE
    aw::template_cpp
    Catch2::Catch2WithMain
)

_aw_setup_tests(aw_template_cpp_tests)
