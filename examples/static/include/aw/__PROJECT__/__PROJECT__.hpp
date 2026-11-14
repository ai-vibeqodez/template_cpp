#pragma once

/**
 * @file __PROJECT__.hpp
 * @brief Public API for the __PROJECT_NAME__ library.
 *
 * Replace "__PROJECT_NAME__" with your library name and update the namespace
 * accordingly.
 */

#include <string_view>

namespace aw::__PROJECT_NAME__ {

/**
 * @class __ProjectCamel__
 * @brief A static library utility class.
 */
class [[nodiscard]] __ProjectCamel__ {
public:
    /**
     * @brief Returns a greeting string.
     * @param[in] name The name to greet.
     * @return A greeting message.
     */
    [[nodiscard]] static std::string_view greet(std::string_view name);

    /**
     * @brief Returns the library version string.
     * @return Version in "X.Y.Z" format.
     */
    [[nodiscard]] static std::string_view version();
};

} // namespace aw::__PROJECT_NAME__
