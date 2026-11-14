// Minimal example: demonstrate __ProjectCamel__::greet.
#include <aw/__PROJECT__/__PROJECT__.h>

#include <iostream>

using namespace aw::__PROJECT_NAME__;

int main() {
    std::cout << __ProjectCamel__::greet("world") << "\n";
    std::cout << "Version: " << __ProjectCamel__::version() << "\n";
    return 0;
}
