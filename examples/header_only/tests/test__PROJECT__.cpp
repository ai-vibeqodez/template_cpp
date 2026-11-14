#include <catch2/catch_test_macros.hpp>
#include <aw/__PROJECT__/__PROJECT__.hpp>

TEST_CASE("__ProjectCamel__::greet returns formatted message", "[__PROJECT__][greet]") {
    REQUIRE(__ProjectCamel__::greet("World") == "Hello, World!");
}

TEST_CASE("__ProjectCamel__::greet handles empty name", "[__PROJECT__][greet]") {
    REQUIRE(__ProjectCamel__::greet("") == "Hello, !");
}

TEST_CASE("__ProjectCamel__::version returns non-empty string", "[__PROJECT__][version]") {
    REQUIRE(!__ProjectCamel__::version().empty());
}
