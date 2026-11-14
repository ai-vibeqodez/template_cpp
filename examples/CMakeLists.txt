# One executable per example; each one focuses on a part of the public API.
set(AW_TEMPLATE_CPP_EXAMPLES
    01_hello
)

foreach(example IN LISTS AW_TEMPLATE_CPP_EXAMPLES)
    add_executable(aw_template_cpp_example_${example} ${example}.cpp)
    target_link_libraries(aw_template_cpp_example_${example} PRIVATE aw::template_cpp)
endforeach()

# Runs every example in sequence (used by `ctest`/CI as a smoke test).
add_custom_target(aw_template_cpp_examples)
foreach(example IN LISTS AW_TEMPLATE_CPP_EXAMPLES)
    add_dependencies(aw_template_cpp_examples aw_template_cpp_example_${example})
endforeach()
