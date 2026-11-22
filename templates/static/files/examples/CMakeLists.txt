# One executable per example; add new ones to the list.
set(@@NAME_UPPER@@_EXAMPLES
    01_basic
)

set(_@@NAME_ID@@_example_options)
if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    list(APPEND _@@NAME_ID@@_example_options STRICT_WARNINGS)
endif()

foreach(example IN LISTS @@NAME_UPPER@@_EXAMPLES)
    aw_add_executable(TARGET @@NAME_ID@@_example_${example}
        SOURCES ${example}.cpp
        LINK_LIBRARIES @@NS@@
        ${_@@NAME_ID@@_example_options})
endforeach()
