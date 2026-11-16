#include "@@NS_PATH@@/@@NAME_ID@@.hpp"

#include <iostream>

int main(int argc, char** argv) {
    std::cout << @@NS@@::greet(argc > 1 ? argv[1] : "world") << '\n';
    return 0;
}
