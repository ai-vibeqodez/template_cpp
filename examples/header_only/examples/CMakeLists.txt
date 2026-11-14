set(__PROJECT_UPPER___EXAMPLES
    01_hello
)

foreach(example IN LISTS __PROJECT_UPPER___EXAMPLES)
    add_executable(__PROJECT_NAME___example_${example} ${example}.cpp)
    target_link_libraries(__PROJECT_NAME___example_${example} PRIVATE aw::__PROJECT_NAME__)
endforeach()

add_custom_target(__PROJECT_NAME___examples)
foreach(example IN LISTS __PROJECT_UPPER___EXAMPLES)
    add_dependencies(__PROJECT_NAME___examples __PROJECT_NAME___example_${example})
endforeach()
