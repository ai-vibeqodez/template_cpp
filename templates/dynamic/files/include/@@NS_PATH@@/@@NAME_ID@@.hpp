#ifndef @@NS_UPPER@@_@@NAME_UPPER@@_HPP
#define @@NS_UPPER@@_@@NAME_UPPER@@_HPP

#include "@@NS_PATH@@/@@NAME_ID@@_export.hpp"

#include <string>
#include <string_view>

@@NS_OPEN@@

/// Returns a greeting for `who`.
[[nodiscard]] @@MACRO_PREFIX@@_API std::string greet(std::string_view who);

#endif // @@NS_UPPER@@_@@NAME_UPPER@@_HPP
@@NS_CLOSE@@
