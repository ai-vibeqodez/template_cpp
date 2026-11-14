// main.cpp — CLI executable entry point

#include <iostream>
#include <string>
#include <string_view>

static void print_usage(std::string_view program_name) {
    std::cerr << "Usage: " << program_name << " [OPTIONS]\n"
              << "Options:\n"
              << "  -h, --help     Show this help message\n"
              << "  -v, --version  Show version information\n"
              << "  -V, --verbose  Enable verbose output\n";
}

static bool parse_args(int argc, char* argv[], bool& verbose) {
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            print_usage(argv[0]);
            return false;
        }
        if (arg == "-v" || arg == "--version") {
            std::cout << "version " << __PROJECT_UPPER___VERSION << "\n";
            return false;
        }
        if (arg == "-V" || arg == "--verbose") {
            verbose = true;
        }
    }
    return true;
}

int main(int argc, char* argv[]) {
    bool verbose = false;
    if (!parse_args(argc, argv, verbose)) {
        return 0;
    }

    std::cout << "Hello from __PROJECT_NAME__ CLI!\n";

    return 0;
}
