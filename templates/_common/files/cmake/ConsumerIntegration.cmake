# ConsumerIntegration.cmake — Reusable consumer integration test helpers
#
# Provides utilities for testing library consumption patterns:
# - add_subdirectory (monorepo/git-submodule scenario)
# - find_package (installed prefix scenario)
# - FetchContent (network fetch scenario)
#
# Usage in a consumer test CMakeLists.txt:
#   include(ConsumerIntegration)
#   aw_consumer_test_library(TARGET consumer_app LIBRARY aw::mylib)
#
# This module is meant to be used by CI workflows testing that downstream projects
# can correctly consume the library via all three integration patterns.

function(aw_consumer_test_executable)
    set(_oneValue TARGET)
    set(_multiValue LIBRARIES)
    cmake_parse_arguments(_CONSUMER "" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _CONSUMER_TARGET)
        message(FATAL_ERROR "aw_consumer_test_executable() requires TARGET argument")
    endif()

    if(NOT _CONSUMER_LIBRARIES)
        message(FATAL_ERROR "aw_consumer_test_executable() requires LIBRARIES argument")
    endif()

    # Assume main.cpp exists in the same directory as the calling CMakeLists.txt
    add_executable(${_CONSUMER_TARGET} main.cpp)
    target_link_libraries(${_CONSUMER_TARGET} PRIVATE ${_CONSUMER_LIBRARIES})
    target_compile_features(${_CONSUMER_TARGET} PRIVATE cxx_std_23)

    # Ensure the executable is tested as part of ctest
    add_test(NAME ${_CONSUMER_TARGET} COMMAND ${_CONSUMER_TARGET})
endfunction()
