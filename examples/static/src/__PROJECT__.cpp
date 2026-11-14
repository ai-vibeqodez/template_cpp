// aw::__PROJECT_NAME__ implementation
#include <aw/__PROJECT__/__PROJECT__.hpp>

#include <sstream>

namespace aw::__PROJECT_NAME__ {

std::string_view __ProjectCamel__::greet(std::string_view name) {
    std::ostringstream oss;
    oss << "Hello, " << name << "!";
    return oss.str();
}

std::string_view __ProjectCamel__::version() {
    return __PROJECT_UPPER___VERSION;
}

} // namespace aw::__PROJECT_NAME__
