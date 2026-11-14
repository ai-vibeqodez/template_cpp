# 📦 Archetype Skeletons

This directory contains starter template files (`.in` extension) for each C++ archetype.

## How to Use

1. **Copy** the relevant `.in` files to your project.
2. **Replace** `@PLACEHOLDERS@` with your project-specific values (e.g., `@PROJECT_NAME@`, `@NAMESPACE@`).
3. **Remove** the `.in` extension.
4. **Customize** the code to match your needs.

## Skeleton Index

### Header-Only Library (`header_only/`)

| File | Description |
|------|-------------|
| [`example.hpp.in`](header_only/example.hpp.in) | Header-only public API header |
| [`CMakeLists.txt.example`](header_only/CMakeLists.txt.example) | How to call `aw_add_header_only_library()` |

### Static Library (`static/`)

| File | Description |
|------|-------------|
| [`example_lib.hpp.in`](static/example_lib.hpp.in) | Static library public header |
| [`example_lib.cpp.in`](static/example_lib.cpp.in) | Static library implementation |
| [`tests/test_example.cpp.in`](static/tests/test_example.cpp.in) | Catch2 test file |
| [`CMakeLists.txt.example`](static/CMakeLists.txt.example) | How to call `aw_add_static_library()` |

### Shared Library (`shared/`)

| File | Description |
|------|-------------|
| [`export_macro.hpp.in`](shared/export_macro.hpp.in) | Cross-platform `AW_API` visibility macro |
| [`DllMain.cpp.in`](shared/DllMain.cpp.in) | Windows DLL entry point |
| [`init.cpp.in`](shared/init.cpp.in) | Library initialization |
| [`plugin_interface.hpp.in`](shared/plugin_interface.hpp.in) | Abstract plugin interface (IPlugin) |
| [`tests/test_plugin.cpp.in`](shared/tests/test_plugin.cpp.in) | Catch2 test for shared library |
| [`CMakeLists.txt.example`](shared/CMakeLists.txt.example) | How to call `aw_add_shared_library()` |

### Plugin Module (`plugin/`)

| File | Description |
|------|-------------|
| [`plugin.cpp.in`](plugin/plugin.cpp.in) | Plugin implementation with `extern "C"` factory |
| [`CMakeLists.txt.example`](plugin/CMakeLists.txt.example) | How to call `aw_add_plugin_module()` |

### C++20 Module (`module/`)

| File | Description |
|------|-------------|
| [`ModuleCard.hin.in`](module/ModuleCard.hin.in) | C++20 module interface unit |
| [`ModuleCard.cppm.in`](module/ModuleCard.cppm.in) | C++20 module implementation unit |
| [`tests/test_module.cpp.in`](module/tests/test_module.cpp.in) | Catch2 test that imports the module |
| [`CMakeLists.txt.example`](module/CMakeLists.txt.example) | How to call `aw_add_cxx_module_library()` |
| [`COMPATIBILITY.md`](module/COMPATIBILITY.md) | Compiler compatibility notes |

### CLI Executable (`cli/`)

| File | Description |
|------|-------------|
| [`main.cpp.in`](cli/main.cpp.in) | CLI `main()` with argument parsing |

### GUI Executable (`gui/`)

| File | Description |
|------|-------------|
| `win32/` | |
| ↳ [`main.cpp.in`](gui/win32/main.cpp.in) | Win32 `WinMain` entry point |
| ↳ [`resource.h.in`](gui/win32/resource.h.in) | Win32 resource header |
| ↳ [`icon.rc.in`](gui/win32/icon.rc.in) | Win32 resource script |
| `macos/` | |
| ↳ [`AppDelegate.swift.in`](gui/macos/AppDelegate.swift.in) | macOS SwiftUI app delegate |
| ↳ [`Info.plist.in`](gui/macos/Info.plist.in) | macOS Info.plist |
| `linux/` | |
| ↳ [`main.cpp.in`](gui/linux/main.cpp.in) | Linux GUI executable |
| ↳ [`app.desktop.in`](gui/linux/app.desktop.in) | Linux desktop entry |
| ↳ [`icons/symbolic.svg.in`](gui/linux/icons/symbolic.svg.in) | Linux app icon |
| [`CMakeLists.txt.example`](gui/CMakeLists.txt.example) | How to call `aw_add_gui_executable()` |

### System Service (`service/`)

| File | Description |
|------|-------------|
| `windows/` | |
| ↳ [`service.cpp.in`](service/windows/service.cpp.in) | Windows SCM `ServiceMain` |
| ↳ [`service.h.in`](service/windows/service.h.in) | Windows service header |
| ↳ [`install_service.bat.in`](service/windows/install_service.bat.in) | Windows install/uninstall script |
| `posix/` | |
| ↳ [`daemon.cpp.in`](service/posix/daemon.cpp.in) | POSIX daemon with `SIGTERM`/`SIGINT` |
| ↳ [`daemon.h.in`](service/posix/daemon.h.in) | POSIX daemon header |
| ↳ [`myapp.service.in`](service/posix/myapp.service.in) | systemd `.service` unit file |
| ↳ [`CMakeLists.txt.example`](service/posix/CMakeLists.txt.example) | How to call `aw_add_service_executable()` |

### Kernel Driver (`kernel/`)

| File | Description |
|------|-------------|
| `windows/` | |
| ↳ [`driver.cpp.in`](kernel/windows/driver.cpp.in) | Windows WDK `DriverEntry` |
| ↳ [`driver.h.in`](kernel/windows/driver.h.in) | Windows WDK driver header |
| ↳ [`CMakeLists.txt.example`](kernel/windows/CMakeLists.txt.example) | How to call `aw_add_kernel_driver()` (Windows) |
| `linux/` | |
| ↳ [`module.c.in`](kernel/linux/module.c.in) | Linux kernel module (`init`/`exit`) |
| ↳ [`Kbuild.in`](kernel/linux/Kbuild.in) | Linux Kbuild file |
| ↳ [`Makefile.in`](kernel/linux/Makefile.in) | Legacy Makefile alternative |
| ↳ [`CMakeLists.txt.example`](kernel/linux/CMakeLists.txt.example) | How to call `aw_add_kernel_driver()` (Linux) |
| [`README_KERNEL.md`](kernel/README_KERNEL.md) | Kernel-mode development guidelines |
