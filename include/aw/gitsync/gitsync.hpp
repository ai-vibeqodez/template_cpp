#ifndef AW_GITSYNC_GITSYNC_HPP
#define AW_GITSYNC_GITSYNC_HPP

#include <string>
#include <string_view>

namespace aw::gitsync {

/// Returns a greeting for `who`.
[[nodiscard]] std::string greet(std::string_view who);

#endif // AW_GITSYNC_GITSYNC_HPP
} // namespace aw::gitsync
