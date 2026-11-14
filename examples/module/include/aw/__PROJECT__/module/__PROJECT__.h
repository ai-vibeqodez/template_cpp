// __PROJECT__.h — C++20 module interface unit

export module __PROJECT_NAME__;

#include <string_view>

namespace aw::__PROJECT_NAME__ {

/**
 * @class __ProjectCamel__
 * @brief A C++20 module-based utility class.
 */
class [[nodiscard]] __ProjectCamel__ {
public:
    [[nodiscard]] static std::string_view greet(std::string_view name);
    [[nodiscard]] static std::string_view version();
};

} // namespace aw::__PROJECT_NAME__
