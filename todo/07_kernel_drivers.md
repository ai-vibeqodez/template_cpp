# Task 07: Kernel Drivers

## Goal

Implement `aw_add_kernel_driver()` CMake helper function in `archetypes/06_kernel.cmake`. This covers Windows WDK (`.sys`) kernel-mode drivers and Linux kernel modules (`.ko`) with Kbuild integration.

## Files to Create/Modify

### Modify
1. **`archetypes/06_kernel.cmake`** — Replace stub with full implementation of `aw_add_kernel_driver()`.

### Create
2. **`archetypes/skeletons/kernel/windows/driver.cpp.in`** — Template for a Windows WDK kernel driver (`DriverEntry` + `Unload`).
3. **`archetypes/skeletons/kernel/windows/driver.h.in`** — Template for Windows WDK driver header.
4. **`archetypes/skeletons/kernel/windows/CMakeLists.txt.example`** — Example of how to call `aw_add_kernel_driver()` for Windows.
5. **`archetypes/skeletons/kernel/linux/module.c.in`** — Template for a Linux kernel module (`init` + `exit` + `MODULE_*` macros).
6. **`archetypes/skeletons/kernel/linux/Kbuild.in`** — Template for a Linux Kbuild file.
7. **`archetypes/skeletons/kernel/linux/Makefile.in`** — Template for a legacy Makefile (alternative to Kbuild).
8. **`archetypes/skeletons/kernel/linux/CMakeLists.txt.example`** — Example of how to call `aw_add_kernel_driver()` for Linux.
9. **`archetypes/skeletons/kernel/README_KERNEL.md`** — Kernel-mode development guidelines and constraints.

## Implementation Details

### 1. `aw_add_kernel_driver(TARGET ...)`

Signature:
```cmake
aw_add_kernel_driver(TARGET <target-name>
    SOURCES <src1.c> <src2.c> ...          # Kernel drivers typically use .c
    [HEADERS <header1.h> ...]              # Kernel headers (typically .h, not .hpp)
    [PLATFORM <windows|linux|auto>]        # Default: auto
    [WDK_VERSION <10.0|11.0>]              # Windows: WDK version (default: 10.0)
    [LINUX_VERSION <6.1|6.6>]              # Linux: minimum kernel version
    [MODULE_NAME <name>]                   # Linux: module name (default: derived from target)
    [KERNEL_SRC_DIR <path>]                # Path to kernel source tree (Linux)
    [WDK_DIR <path>]                       # Path to WDK installation (Windows)
)
```

Implementation:
- **Detect platform** using `CMAKE_SYSTEM_NAME` and the optional `PLATFORM` parameter.
- **Windows WDK**: Set flags for kernel-mode compilation (`/kernel`, `/W4`, `/WX`, `/Zc:wchar_t`, etc.). Link against `ntoskrnl.lib`, `wdm.lib`, `wdk.lib`.
- **Linux Kbuild**: Generate a `Kbuild` file and invoke `make -C <kernel_src> M=<build_dir> modules`.
- **Both**: Set appropriate compile definitions (`_KERNEL_MODE`, `__KERNEL__`).
- **No ALIAS target** — kernel drivers are not imported by other projects.
- **No install rules by default** — kernel drivers are deployed via specialized mechanisms.

### 2. Windows WDK Driver Skeleton

```cpp
// driver.cpp — Windows WDK kernel-mode driver
// Compile with: WDK x64 toolchain (cl.exe with /kernel flag)

#include <driver.h>

/**
 * @brief DriverEntry — entry point called by the Windows kernel loader.
 * @param DriverObject Pointer to the DRIVER_OBJECT structure.
 * @param RegistryPath Registry path for this driver.
 * @return STATUS_SUCCESS on success, appropriate NTSTATUS on failure.
 */
NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath) {
    UNREFERENCED_PARAMETER(RegistryPath);

    // Initialize driver object callbacks.
    DriverObject->DriverUnload = DriverUnload;
    DriverObject->DriverStartIo = nullptr;
    DriverObject->DriverStopIo = nullptr;

    // TODO: Register device interfaces, create device objects,
    //       set up IRP handlers, etc.

    return STATUS_SUCCESS;
}

/**
 * @brief DriverUnload — cleanup called when the driver is unloaded.
 * @param DriverObject Pointer to the DRIVER_OBJECT structure.
 */
VOID DriverUnload(PDRIVER_OBJECT DriverObject) {
    // TODO: Delete device objects, unregister interfaces,
    //       free allocated resources.
}
```

**Windows WDK header skeleton:**
```cpp
// driver.h — Windows WDK driver header
#pragma once

#include <ntddk.h>

// Driver unload callback.
VOID DriverUnload(PDRIVER_OBJECT DriverObject);
```

**Windows WDK compile flags (set by CMake helper):**
```cmake
# Windows WDK flags (kernel mode):
#   /kernel          — Compile as kernel-mode code
#   /W4 /WX          — Warning level 4, warnings as errors
#   /Zc:wchar_t      — wchar_t is a native type
#   /D "_KERNEL_MODE" — Kernel-mode define
#   /D "UNICODE" /D "_UNICODE" — Unicode
#   /D "NTDDI_VERSION=NTDDI_WIN10" — Minimum Windows version
#   /D "_WIN32_WINNT=0x0A00" — Windows 10
```

### 3. Linux Kernel Module Skeleton

```c
// module.c — Linux kernel module
#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

static int __init my_driver_init(void) {
    pr_info("my_driver: loading module\n");
    // TODO: Initialize driver resources, register device, etc.
    return 0;
}

static void __exit my_driver_exit(void) {
    pr_info("my_driver: unloading module\n");
    // TODO: Cleanup resources, unregister device, etc.
}

module_init(my_driver_init);
module_exit(my_driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A aw::kernel driver module");
MODULE_VERSION("1.0.0");
MODULE_ALIAS("my_driver");
```

### 4. Kbuild Template

```makefile
# Kbuild — Linux kernel module build file
# Generated by aw_add_kernel_driver()

# Module name and source files
obj-m := @MODULE_NAME@.o
@MODULE_NAME@-y := module.o

# Kernel source directory (set by CMake)
KDIR := @KERNEL_SRC_DIR@

# Build target: make -C <kdir> M=<pwd> modules
all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
```

### 5. Kernel-Mode Constraints (from `README_KERNEL.md`)

```markdown
# Kernel-Mode Development Guidelines

## General Constraints

1. **No user-space CRT**: Kernel drivers cannot use `malloc`, `free`, `new`, `delete`, `printf`, `cout`, or any user-space standard library. Use kernel allocators (`ExAllocatePool`, `kmalloc`) and logging (`DbgPrint`, `pr_info`).
2. **No exceptions**: C++ exceptions are not supported in kernel mode. Use `NTSTATUS` (Windows) or `int` return codes (Linux).
3. **No threading primitives**: Use kernel synchronization primitives (`KEVENT`, `KMUTEX`, `spin_lock`, `mutex_lock`).
4. **No dynamic linking**: Kernel drivers are loaded directly into kernel space. All code must be linked into the `.sys` or `.ko` file.
5. **No heap allocation in interrupt context**: Use pool/stack allocation and avoid `kmalloc` in interrupt handlers.

## Windows WDK Specific

- Target minimum Windows version via `NTDDI_VERSION` and `_WIN32_WINNT`.
- Use `WDF` (Windows Driver Framework) for modern drivers — avoid raw `IRP` handling unless necessary.
- Sign all drivers for Windows 10+: WHQL certification or test signing (`signtool sign`).
- Use `!analyze -v` in WinDbg for crash analysis.

## Linux Kernel Specific

- Target minimum kernel version via `LINUX_VERSION_CODE` and `KERNEL_VERSION()`.
- Use `module_init`/`module_exit` for initialization/cleanup.
- License must be GPL-compatible (`MODULE_LICENSE("GPL")`).
- Use `pr_info`, `pr_err`, `dev_info` for logging (not `printf`).
- Build against a specific kernel source tree (`KERNEL_SRC_DIR`).

## Build System Notes

- **Windows**: Requires WDK installation and the `wsddetect.cmake` module (or manual WDK path).
- **Linux**: Requires kernel source headers (`linux-headers-$(uname -r)` or full kernel source tree).
- Cross-compilation is complex for kernel drivers — build on the target platform when possible.
- Kernel drivers are platform-specific and cannot be shared across OSes.
```

## Acceptance Criteria

1. **`aw_add_kernel_driver()` compiles**: A kernel driver target builds without errors on the current platform.
2. **Windows WDK flags**: On Windows, the target uses `/kernel` and WDK-specific compile/link flags.
3. **Linux Kbuild**: On Linux, a `Kbuild` file is generated and the driver builds against the kernel source tree.
4. **Kernel-mode constraints documented**: `README_KERNEL.md` clearly states the constraints (no user-space CRT, no exceptions, no dynamic linking).
5. **Skeletons follow conventions**: All skeleton files use kernel-appropriate patterns (C for kernel, proper `MODULE_*` macros, `DriverEntry`/`DriverUnload` for Windows).
6. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes (kernel drivers are opt-in; the default `template_cpp` library remains user-space).
