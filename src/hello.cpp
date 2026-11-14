// aw::template_cpp implementation — mirrors the header tree under src/.
#include <aw/template_cpp/hello.hpp>

#include <sstream>

namespace aw::template_cpp {

std::string Hello::greet(std::string_view name) {
    std::ostringstream oss;
    oss << "Hello, " << name << "! Welcome to aw::template_cpp.";
    return oss.str();
}

std::string Hello::version() {
    // Read from VERSION file at build time.
    return TEMPLATE_CPP_VERSION;
}

std::string Hello::name() {
    return "template_cpp";
}

} // namespace aw::template_cpp
