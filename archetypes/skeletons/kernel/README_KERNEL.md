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
- Compile with `/kernel` flag; the output is a `.sys` file, not an `.exe` or `.dll`.

## Linux Kernel Specific

- Target minimum kernel version via `LINUX_VERSION_CODE` and `KERNEL_VERSION()`.
- Use `module_init`/`module_exit` for initialization/cleanup.
- License must be GPL-compatible (`MODULE_LICENSE("GPL")`).
- Use `pr_info`, `pr_err`, `dev_info` for logging (not `printf`).
- Build against a specific kernel source tree (`KERNEL_SRC_DIR`).
- The `.ko` module is loaded via `insmod`/`modprobe` and unloaded via `rmmod`.

## Build System Notes

- **Windows**: Requires WDK installation and the MSVC toolchain. The `aw_add_kernel_driver()` helper configures `/kernel`, `/W4`, and links against `ntoskrnl.lib`, `wdm.lib`, `wdfldr.lib`.
- **Linux**: Requires kernel source headers (`linux-headers-$(uname -r)` or a full kernel source tree). The helper generates a `Kbuild` file and invokes `make -C <kernel_src> M=<build_dir> modules`.
- Cross-compilation is complex for kernel drivers — build on the target platform when possible.
- Kernel drivers are platform-specific and cannot be shared across OSes.

## CMake Integration

The `aw_add_kernel_driver()` function handles platform detection, flag configuration, and skeleton generation. Use `PLATFORM windows` or `PLATFORM linux` to force the target platform, or let it auto-detect from `CMAKE_SYSTEM_NAME`.

Key parameters:

| Parameter | Description | Default |
|---|---|---|
| `TARGET` | Target name | *(required)* |
| `SOURCES` | Source files | *(required)* |
| `PLATFORM` | `windows`, `linux`, or `auto` | `auto` |
| `WDK_VERSION` | Windows WDK version | `10.0` |
| `LINUX_VERSION` | Minimum Linux kernel version | `6.1` |
| `MODULE_NAME` | Linux module name | Derived from `TARGET` |
| `KERNEL_SRC_DIR` | Linux kernel source path | Auto-detected |
| `WDK_DIR` | WDK installation path | System default |

## Testing

- **Windows**: Use `WinDbg` with kernel debugging (VM + serial pipe, or Hyper-V). Load the `.sys` and step through `DriverEntry`.
- **Linux**: Load the `.ko` with `insmod` and inspect `dmesg` for `pr_info`/`pr_err` output. Use `kmemleak` and `lockdep` for debugging.
