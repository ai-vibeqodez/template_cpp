# Task 06: System Service and Daemon

## Goal

Implement `aw_add_service_executable()` CMake helper function in `archetypes/05_service.cmake`. This covers Windows Service Control Manager (SCM) services and POSIX daemon processes with `systemd` integration.

## Files to Create/Modify

### Modify
1. **`archetypes/05_service.cmake`** — Replace stub with full implementation of `aw_add_service_executable()`.

### Create
2. **`archetypes/skeletons/service/windows/service.cpp.in`** — Template for a Windows SCM service (ServiceMain + ControlHandler).
3. **`archetypes/skeletons/service/windows/service.h.in`** — Template for Windows service header.
4. **`archetypes/skeletons/service/windows/install_service.bat.in`** — Template for a batch script to install/uninstall the service.
5. **`archetypes/skeletons/service/posix/daemon.cpp.in`** — Template for a POSIX daemon (fork, setsid, SIGTERM/SIGINT handling).
6. **`archetypes/skeletons/service/posix/daemon.h.in`** — Template for POSIX daemon header.
7. **`archetypes/skeletons/service/posix/myapp.service.in`** — Template for a `systemd` `.service` unit file.
8. **`archetypes/skeletons/service/posix/CMakeLists.txt.example`** — Example of how to call `aw_add_service_executable()`.

## Implementation Details

### 1. `aw_add_service_executable(TARGET ...)`

Signature:
```cmake
aw_add_service_executable(TARGET <target-name>
    SOURCES <src1.cpp> <src2.cpp> ...
    [HEADERS <header1.hpp> ...]
    [LINK_LIBRARIES <dep1> <dep2> ...]
    [COMPILE_DEFINITIONS <DEF1> <DEF2> ...]
    [SERVICE_NAME <name>]              # Default: derived from target
    [SERVICE_DISPLAY_NAME <name>]      # Default: same as SERVICE_NAME
    [SERVICE_DESCRIPTION <desc>]       # Default: "A aw::service application"
    [PLATFORM <windows|posix|auto>]    # Default: auto (detect from CMAKE_SYSTEM_NAME)
    [INSTALL_DESTINATION <dir>]        # Default: ${CMAKE_INSTALL_BINDIR}
)
```

Implementation:
- **Detect platform** using `CMAKE_SYSTEM_NAME` and the optional `PLATFORM` parameter.
- **Windows**: Create a `WIN32` executable (no console). Include Windows SCM headers and a `ServiceMain` entry point.
- **POSIX**: Create a standard executable that daemonizes (fork + setsid). Include `systemd` notification support via `sd_notify()` (libsystemd) or a fallback.
- Apply `target_compile_features(<target> PUBLIC cxx_std_20)`.
- Set platform-specific compile definitions.
- Call `_aw_set_warnings()`, `_aw_apply_sanitizers()`, `_aw_apply_coverage()`, `_aw_add_lint()`.
- Install rules:
  - Windows: binary to `${CMAKE_INSTALL_BINDIR}` + install script to `${CMAKE_INSTALL_DATAROOTDIR}/scripts/`.
  - Linux: binary to `${CMAKE_INSTALL_BINDIR}`, `.service` file to `${CMAKE_INSTALL_DATAROOTDIR}/systemd/system/`.
- **No ALIAS target** — services are not imported by other projects.

### 2. Windows Service Skeleton

```cpp
// service.cpp — Windows Service Control Manager service
#include <windows.h>
#include <service.h>  // Local header

static SERVICE_STATUS g_service_status{};
static SERVICE_STATUS_HANDLE g_service_handle{};
static HANDLE g_stop_event{};

/**
 * @brief Service control handler — processes SCM commands.
 */
static void WINAPI service_control_handler(DWORD control) {
    switch (control) {
        case SERVICE_CONTROL_STOP:
        case SERVICE_CONTROL_SHUTDOWN:
            g_service_status.dwWin32ExitCode = 0;
            g_service_status.dwCurrentState = SERVICE_STOPPED;
            SetEvent(g_stop_event);
            break;
        case SERVICE_CONTROL_PAUSE:
            g_service_status.dwCurrentState = SERVICE_PAUSED;
            break;
        case SERVICE_CONTROL_CONTINUE:
            g_service_status.dwCurrentState = SERVICE_RUNNING;
            break;
        case SERVICE_CONTROL_INTERROGATE:
            break;
        default:
            break;
    }
    SetServiceStatus(g_service_handle, &g_service_status);
}

/**
 * @brief ServiceMain — entry point registered with the SCM.
 */
static void WINAPI service_main(DWORD argc, LPWSTR* argv) {
    g_service_handle = RegisterServiceCtrlHandlerW(L"@SERVICE_NAME@", service_control_handler);
    if (!g_service_handle) {
        return;
    }

    g_service_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    g_service_status.dwCurrentState = SERVICE_START_PENDING;
    g_service_status.dwControlsAccepted = SERVICE_STOP_ACCEPTED
                                         | SERVICE_PAUSE_CONTINUE_ACCEPTED;
    SetServiceStatus(g_service_handle, &g_service_status);

    g_stop_event = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!g_stop_event) {
        g_service_status.dwCurrentState = SERVICE_STOPPED;
        g_service_status.dwWin32ExitCode = ERROR_FAILED_SERVICE_CONTROLLER_CONNECT;
        SetServiceStatus(g_service_handle, &g_service_status);
        return;
    }

    // Initialize service.
    g_service_status.dwCurrentState = SERVICE_RUNNING;
    SetServiceStatus(g_service_handle, &g_service_status);

    // Main service loop.
    WaitForSingleObject(g_stop_event, INFINITE);

    // Cleanup.
    CloseHandle(g_stop_event);
    g_service_status.dwCurrentState = SERVICE_STOPPED;
    g_service_status.dwWin32ExitCode = 0;
    SetServiceStatus(g_service_handle, &g_service_status);
}

int main() {
    SERVICE_TABLE_ENTRYW service_table[] = {
        {L"@SERVICE_NAME@", service_main},
        {nullptr, nullptr}
    };

    if (!StartServiceCtrlDispatcherW(service_table)) {
        // Not running as a service — fall back to foreground mode for debugging.
        // TODO: Implement foreground mode.
    }

    return 0;
}
```

### 3. POSIX Daemon Skeleton

```cpp
// daemon.cpp — POSIX daemon process with SIGTERM/SIGINT handling
#include <daemon.h>

#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

static volatile sig_atomic_t g_running = 1;

/**
 * @brief Signal handler for SIGTERM and SIGINT.
 */
static void signal_handler(int signum) {
    g_running = 0;
}

/**
 * @brief Daemonize the current process.
 * Forks, setsid, closes stdio, changes working directory.
 */
static int daemonize() {
    switch (fork()) {
        case -1:
            return -1;
        case 0:
            // Child process — continue.
            break;
        default:
            // Parent — exit.
            _exit(0);
    }

    if (setsid() == -1) {
        return -1;
    }

    // Ignore SIGHUP to prevent the daemon from being terminated
    // when the parent terminal closes.
    signal(SIGHUP, SIG_IGN);

    switch (fork()) {
        case -1:
            return -1;
        case 0:
            // Second child — continue.
            break;
        default:
            // First child — exit.
            _exit(0);
    }

    // Redirect stdio to /dev/null.
    int dev_null = open("/dev/null", O_RDWR);
    if (dev_null >= 0) {
        dup2(dev_null, STDIN_FILENO);
        dup2(dev_null, STDOUT_FILENO);
        dup2(dev_null, STDERR_FILENO);
        if (dev_null > STDERR_FILENO) {
            close(dev_null);
        }
    }

    // Change working directory to root.
    if (chdir("/") != 0) {
        return -1;
    }

    // Clear file mode creation mask.
    umask(0);

    return 0;
}

/**
 * @brief Notify systemd that the daemon is ready.
 * Uses sd_notify() if libsystemd is available; no-op otherwise.
 */
static void notify_systemd_ready() {
#ifdef HAVE_LIBSYSTEMD
    // sd_notify(0, "READY=1");
#endif
    (void)0; // Placeholder — implement when libsystemd is linked.
}

int main() {
    // Install signal handlers.
    signal(SIGTERM, signal_handler);
    signal(SIGINT, signal_handler);

    // Daemonize.
    if (daemonize() != 0) {
        fprintf(stderr, "Failed to daemonize\n");
        return 1;
    }

    // Notify systemd.
    notify_systemd_ready();

    // Main daemon loop.
    while (g_running) {
        // TODO: Implement daemon logic.
        sleep(1);
    }

    return 0;
}
```

### 4. systemd `.service` Unit Template

```ini
# myapp.service — systemd unit file for the aw::service daemon
# Install to: /etc/systemd/system/myapp.service
# Enable: systemctl enable myapp
# Start:  systemctl start myapp

[Unit]
Description=@SERVICE_DISPLAY_NAME@
After=network.target

[Service]
Type=notify
ExecStart=@CMAKE_INSTALL_FULL_BINDIR@/@TARGET@
User=@SERVICE_USER@
Group=@SERVICE_GROUP@
WorkingDirectory=@CMAKE_INSTALL_PREFIX@

# Security hardening.
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=true
ReadWritePaths=@CMAKE_INSTALL_PREFIX@/var

# Restart policy.
Restart=on-failure
RestartSec=5s

# Logging.
StandardOutput=journal
StandardError=journal
SyslogIdentifier=@SERVICE_NAME@

[Install]
WantedBy=multi-user.target
```

### 5. Windows Install Script Template

```bat
:: install_service.bat — Install/uninstall the aw::service Windows service
:: Usage: install_service.bat [install|uninstall|start|stop]

@echo off
set SERVICE_NAME=@SERVICE_NAME@
set SERVICE_DISPLAY_NAME=@SERVICE_DISPLAY_NAME@
set SERVICE_PATH=%~dp0@TARGET@.exe

if "%1"=="install" (
    sc create "%SERVICE_NAME%" binPath= "%SERVICE_PATH%" start= auto
    sc description "%SERVICE_NAME%" "@SERVICE_DESCRIPTION@"
    echo Service installed.
) else if "%1"=="uninstall" (
    sc stop "%SERVICE_NAME%"
    sc delete "%SERVICE_NAME%"
    echo Service uninstalled.
) else if "%1"=="start" (
    sc start "%SERVICE_NAME%"
    echo Service started.
) else if "%1"=="stop" (
    sc stop "%SERVICE_NAME%"
    echo Service stopped.
) else (
    echo Usage: %~nx0 [install|uninstall|start|stop]
)
```

## Acceptance Criteria

1. **`aw_add_service_executable()` compiles**: A service executable target builds without errors.
2. **Windows SCM service**: On Windows, the target produces a `WIN32` executable with `ServiceMain` and `ControlHandler` entry points.
3. **POSIX daemon**: On Linux/macOS, the target produces a daemon that forks, setsid, and handles `SIGTERM`/`SIGINT`.
4. **systemd integration**: On Linux, a `.service` unit file is generated and installed to `${CMAKE_INSTALL_DATAROOTDIR}/systemd/system/`.
5. **Windows install script**: On Windows, an `install_service.bat` script is generated for install/uninstall/start/stop.
6. **Security hardening**: The systemd unit includes `NoNewPrivileges`, `ProtectSystem`, `ProtectHome`, and `PrivateTmp`.
7. **Skeletons follow conventions**: All skeleton files follow `docs/CPP_GUIDELINES.md`.
8. **Build + tests pass**: The full `template-cpp` project still builds and all tests pass after these changes.
