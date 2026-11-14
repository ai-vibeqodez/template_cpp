#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_string.hpp>
#include <aw/template_cpp/hello.hpp>

#include <string>

using namespace aw::template_cpp;

TEST_CASE("Hello::greet returns a formatted message", "[hello][greet]") {
    REQUIRE(Hello::greet("World") == "Hello, World! Welcome to aw::template_cpp.");
    REQUIRE(Hello::greet("") == "Hello, ! Welcome to aw::template_cpp.");
    REQUIRE(Hello::greet("C++20") == "Hello, C++20! Welcome to aw::template_cpp.");
}

TEST_CASE("Hello::version returns a non-empty semver-like string", "[hello][version]") {
    auto v = Hello::version();
    REQUIRE(!v.empty());
    // Should contain at least one dot (X.Y.Z format).
    REQUIRE(v.find('.') != std::string::npos);
}

TEST_CASE("Hello::name returns the canonical library name", "[hello][name]") {
    REQUIRE(Hello::name() == "template_cpp");
}

TEST_CASE("Hello is [[nodiscard]]", "[hello][nodiscard]") {
    // This test verifies the class compiles as nodiscard — the warning
    // would only appear in a compiler diagnostic, not at runtime.
    [[maybe_unused]] auto g = Hello::greet("test");
    [[maybe_unused]] auto v = Hello::version();
    [[maybe_unused]] auto n = Hello::name();
    SUCCEED();
}
