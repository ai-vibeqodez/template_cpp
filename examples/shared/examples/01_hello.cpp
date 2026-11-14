// Minimal example: demonstrate __ProjectCamel__::greet and __ProjectCamel__::version.
#include <aw/__PROJECT__/__PROJECT__.hpp>

#include <iostream>

using namespace aw::__PROJECT_NAME__;

int main() {
    std::cout << __ProjectCamel__::greet("world") << "\n";
    std::cout << "Library: " << __ProjectCamel__::name() << "\n";
    std::cout << "Version: " << __ProjectCamel__::version() << "\n";
    return 0;
}
