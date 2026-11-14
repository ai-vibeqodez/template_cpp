#pragma once

/**
 * @file __PROJECT__.hpp
 * @brief Public API for the header-only __PROJECT_NAME__ library.
 *
 * All implementation lives in the header (inline functions or
 * template definitions). No corresponding .cpp file is needed.
 */

#include <string_view>

namespace aw::__PROJECT_NAME__ {

/**
 * @class __ProjectCamel__
 * @brief A header-only utility class.
 */
class [[nodiscard]] __ProjectCamel__ {
public:
    /**
     * @brief Returns a greeting string.
     * @param[in] name The name to greet.
     * @return A greeting message.
     */
    [[nodiscard]] inline static std::string_view greet(std::string_view name) {
        return "Hello, " + std::string(name) + "!";
    }

    /**
     * @brief Returns the library version string.
     * @return Version in "X.Y.Z" format.
     */
    [[nodiscard]] inline static std::string_view version() {
        return __PROJECT_UPPER___VERSION;
    }
};

} // namespace aw::__PROJECT_NAME__
