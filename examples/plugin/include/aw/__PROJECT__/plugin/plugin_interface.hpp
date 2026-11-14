#pragma once

/**
 * @file plugin_interface.hpp
 * @brief Abstract plugin interface — all plugins must implement this.
 */

#include <string_view>

#include "export_macro.hpp"

namespace aw::plugin {

/**
 * @class IPlugin
 * @brief Abstract base class for all plugin modules.
 */
class AW_API IPlugin {
public:
    virtual ~IPlugin() = default;

    [[nodiscard]] virtual std::string_view name() const = 0;
    [[nodiscard]] virtual std::string_view version() const = 0;
    virtual void initialize() = 0;
    virtual void cleanup() = 0;
};

} // namespace aw::plugin
