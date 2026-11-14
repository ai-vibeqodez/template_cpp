// Minimal kernel example — prints a message.
#include <iostream>

int main() {
    std::cout << "Kernel archetype loaded.\n";
    std::cout << "Build with kernel headers: make -C /lib/modules/$(uname -r)/build M=$(pwd) modules\n";
    return 0;
}
