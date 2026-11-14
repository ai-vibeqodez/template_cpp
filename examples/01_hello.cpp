// Minimal example: demonstrate Hello::greet, Hello::version, and Hello::name.
#include <aw/template_cpp/hello.hpp>

#include <iostream>

using namespace aw::template_cpp;

int main() {
    // Greet a user.
    std::cout << Hello::greet("ai-warevo") << "\n";

    // Report library identity.
    std::cout << "Library: " << Hello::name() << "\n";
    std::cout << "Version: " << Hello::version() << "\n";

    return 0;
}
