// __PROJECT__.cpp — Plugin module with extern "C" factory entry point

#include <aw/__PROJECT__/plugin_interface.hpp>

#include <string>

namespace {

class __ProjectCamel__ : public aw::plugin::IPlugin {
public:
    [[nodiscard]] std::string_view name() const override {
        return "__PROJECT_NAME__";
    }

    [[nodiscard]] std::string_view version() const override {
        return "0.0.0";
    }

    void initialize() override {}
    void cleanup() override {}
};

} // namespace

extern "C" {

AW_API void* create___PROJECT__() {
    return new __ProjectCamel__();
}

AW_API void destroy_plugin(void* plugin) {
    delete static_cast<__ProjectCamel__*>(plugin);
}

} // extern "C"
