#include "aw/gitsync/gitsync.hpp"

#include <iostream>
#include <span>
#include <string_view>

int main(int argc, char* argv[]) {
    const std::span<char*> args(argv, static_cast<std::size_t>(argc));
    const std::string_view name = args.size() > 1 ? args[1] : "world";
    std::cout << aw::gitsync::greet(name) << '\n';
    return 0;
}
