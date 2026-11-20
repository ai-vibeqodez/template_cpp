#include "@@NS_PATH@@/@@NAME_ID@@.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("greet greets", "[@@NAME_ID@@]") {
    REQUIRE(@@NS@@::greet("world") == "Hello, world!");
}
