# One executable per example; add new ones to the list.
set(@@NAME_UPPER@@_EXAMPLES
    01_basic
)

foreach(example IN LISTS @@NAME_UPPER@@_EXAMPLES)
    add_executable(@@NAME_ID@@_example_${example} ${example}.cpp)
    target_link_libraries(@@NAME_ID@@_example_${example} PRIVATE @@NS@@)
    target_compile_options(@@NAME_ID@@_example_${example} PRIVATE ${AW_WARNINGS} ${AW_STRICT_WARNINGS})
endforeach()
