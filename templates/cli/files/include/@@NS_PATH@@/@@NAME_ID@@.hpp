#pragma once

#include <string>
#include <string_view>

@@NS_OPEN@@

/// Returns a greeting for `who`.
[[nodiscard]] std::string greet(std::string_view who);

@@NS_CLOSE@@
