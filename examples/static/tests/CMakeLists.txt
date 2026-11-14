include(FetchContent)

FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG        v3.16.1
    GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(Catch2)

add_executable(__PROJECT_NAME___tests
    test__PROJECT__.cpp
)

target_link_libraries(__PROJECT_NAME___tests PRIVATE
    aw::__PROJECT_NAME__
    Catch2::Catch2WithMain
)

aw_setup_tests(__PROJECT_NAME___tests)
