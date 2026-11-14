#pragma once

/**
 * @file hello.hpp
 * @brief Core public API for the aw::template_cpp library.
 *
 * This header is the entry point for the template library. It demonstrates
 * the namespace layout, Doxygen documentation style, and .hpp/.cpp separation
 * conventions used across the ai-warevo ecosystem.
 */

#include <string>

namespace aw::template_cpp {

/**
 * @class Hello
 * @brief A minimal utility class demonstrating the template library structure.
 *
 * Every public class follows the Doxygen convention with @class, @brief,
 * @return, and @throws tags. Private members use trailing_underscore_.
 */
class [[nodiscard]] Hello {
public:
    /**
     * @brief Returns a greeting string for the given name.
     * @param[in] name The name to greet.
     * @return A greeting message.
     */
    [[nodiscard]] static std::string greet(std::string_view name);

    /**
     * @brief Returns the library version string.
     * @return Version in "X.Y.Z" format.
     */
    [[nodiscard]] static std::string version();

    /**
     * @brief Returns the library name.
     * @return "template_cpp".
     */
    [[nodiscard]] static std::string name();

private:
    // Intentionally empty — this is a stateless utility class.
};

} // namespace aw::template_cpp
