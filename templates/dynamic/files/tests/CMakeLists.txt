include(Tests)
aw_test_target(NAME @@NAME@@ TESTS_SOURCE @@NAME_ID@@_tests.cpp LINK_TARGET @@NS@@::@@NAME@@)
