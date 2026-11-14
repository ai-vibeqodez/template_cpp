#include <aw/__PROJECT__/__PROJECT__.hpp>

#include <iostream>

using namespace aw::__PROJECT_NAME__;

int main() {
    std::cout << __ProjectCamel__::greet("world") << "\n";
    std::cout << "Library: " << __PROJECT_NAME__ << "\n";
    std::cout << "Version: " << __ProjectCamel__::version() << "\n";
    return 0;
}
