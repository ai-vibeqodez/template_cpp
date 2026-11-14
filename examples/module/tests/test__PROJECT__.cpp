#include <catch2/catch_test_macros.hpp>

import __PROJECT_NAME__;

TEST_CASE("__ProjectCamel__::greet returns formatted message", "[__PROJECT__][greet]") {
    using namespace aw::__PROJECT_NAME__;
    REQUIRE(__ProjectCamel__::greet("World") == "Hello, World!");
}

TEST_CASE("__ProjectCamel__::version returns non-empty string", "[__PROJECT__][version]") {
    using namespace aw::__PROJECT_NAME__;
    REQUIRE(!__ProjectCamel__::version().empty());
}
