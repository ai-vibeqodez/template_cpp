#include "aw/gitsync/gitsync.hpp"

namespace aw::gitsync {

std::string greet(std::string_view who) {
    return "Hello, " + std::string(who) + "!";
}

} // namespace aw::gitsync
