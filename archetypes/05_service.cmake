# =============================================================================
# 05_service.cmake — System service and daemon executable archetype
#
# Provides:
#   aw_add_service_executable()  — Cross-platform service (Windows SCM,
#                                  POSIX daemon, systemd .service unit)
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.
set(_aw_service_dir "${CMAKE_CURRENT_LIST_DIR}")

# ===========================================================================
# aw_add_service_executable()
#
# Create an executable designed to run as a system service:
#   - Windows: Registers with the Service Control Manager (SCM)
#              as a WIN32 service with ServiceMain + ControlHandler.
#   - Linux:   Generates a systemd .service unit file with security
#              hardening (NoNewPrivileges, ProtectSystem, etc.).
#   - macOS:   Generates a POSIX daemon with fork/setsid and SIGTERM/SIGINT
#              handling.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   SERVICE_NAME <name>          Service name used by SCM/systemd.
#                                Default: derived from TARGET (underscores
#                                replaced with hyphens).
#   SERVICE_DISPLAY_NAME <name>  Human-readable display name.
#                                Default: same as SERVICE_NAME.
#   SERVICE_DESCRIPTION <desc>   Short description of the service.
#                                Default: "An aw::service application".
#   SERVICE_USER <user>          Unix user to run the daemon as.
#                                Default: "root".
#   SERVICE_GROUP <group>        Unix group for the daemon.
#                                Default: "root".
#   PLATFORM <windows|posix|auto>
#                                Force target platform.
#                                Default: auto (detect from CMAKE_SYSTEM_NAME).
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_service_executable(TARGET my_service
#       SOURCES src/my_service.cpp
#       LINK_LIBRARIES aw::my_lib
#       SERVICE_NAME "my-service"
#       SERVICE_USER "myapp"
#       SERVICE_GROUP "myapp"
#   )
# ===========================================================================
function(aw_add_service_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "SERVICE_NAME;SERVICE_DISPLAY_NAME;SERVICE_DESCRIPTION;SERVICE_USER;SERVICE_GROUP;PLATFORM;INSTALL_DESTINATION"
        "SOURCES;HEADERS;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT TARGET)
        message(FATAL_ERROR
            "aw_add_service_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_service_executable(${TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_SERVICE_NAME)
        set(ARG_SERVICE_NAME "${TARGET}")
        string(REPLACE "_" "-" ARG_SERVICE_NAME "${ARG_SERVICE_NAME}")
    endif()

    if(NOT ARG_SERVICE_DISPLAY_NAME)
        set(ARG_SERVICE_DISPLAY_NAME "${ARG_SERVICE_NAME}")
    endif()

    if(NOT ARG_SERVICE_DESCRIPTION)
        set(ARG_SERVICE_DESCRIPTION "An aw::service application")
    endif()

    if(NOT ARG_SERVICE_USER)
        set(ARG_SERVICE_USER "root")
    endif()

    if(NOT ARG_SERVICE_GROUP)
        set(ARG_SERVICE_GROUP "root")
    endif()

    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    # -------------------------------------------------------------------
    # 2. Detect platform
    # -------------------------------------------------------------------
    if(ARG_PLATFORM)
        if(ARG_PLATFORM STREQUAL "windows")
            set(_aw_platform "windows")
        elseif(ARG_PLATFORM STREQUAL "posix")
            set(_aw_platform "posix")
        else()
            message(FATAL_ERROR
                "aw_add_service_executable(${TARGET}): "
                "PLATFORM must be 'windows', 'posix', or 'auto'")
        endif()
    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        set(_aw_platform "windows")
    else()
        set(_aw_platform "posix")
    endif()

    # -------------------------------------------------------------------
    # 3. Create target
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # Windows: WIN32 flag → GUI subsystem (no console window).
        add_executable(${TARGET} WIN32 ${ARG_SOURCES})
    else()
        # POSIX: standard executable.
        add_executable(${TARGET} ${ARG_SOURCES})
    endif()

    # No ALIAS target — services are not imported by other projects.

    # -------------------------------------------------------------------
    # 4. Compile features
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} PUBLIC cxx_std_20)

    # -------------------------------------------------------------------
    # 5. Platform-specific compile definitions
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        target_compile_definitions(${TARGET} PRIVATE
            WIN32_LEAN_AND_MEAN
            _UNICODE
            UNICODE
        )
    else()
        target_compile_definitions(${TARGET} PRIVATE
            AW_SERVICE_POSIX
        )
    endif()

    # -------------------------------------------------------------------
    # 6. User-provided compile definitions
    # -------------------------------------------------------------------
    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 7. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 8. Add skeleton sources and installable artifacts
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # --- Windows service source ---
        set(_aw_svc_header "${_aw_service_dir}/skeletons/service/windows/service.h.in")
        set(_aw_svc_impl   "${_aw_service_dir}/skeletons/service/windows/service.cpp.in")

        if(EXISTS "${_aw_svc_header}")
            configure_file(
                "${_aw_svc_header}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.h"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.h")
        endif()

        if(EXISTS "${_aw_svc_impl}")
            configure_file(
                "${_aw_svc_impl}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.cpp"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_service.cpp")
        endif()

        # --- Windows install script ---
        set(_aw_install_bat "${_aw_service_dir}/skeletons/service/windows/install_service.bat.in")
        if(EXISTS "${_aw_install_bat}")
            configure_file(
                "${_aw_install_bat}"
                "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat"
                @ONLY
            )
        endif()

    else()
        # --- POSIX daemon source ---
        set(_aw_daemon_header "${_aw_service_dir}/skeletons/service/posix/daemon.h.in")
        set(_aw_daemon_impl   "${_aw_service_dir}/skeletons/service/posix/daemon.cpp.in")

        if(EXISTS "${_aw_daemon_header}")
            configure_file(
                "${_aw_daemon_header}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.h"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.h")
        endif()

        if(EXISTS "${_aw_daemon_impl}")
            configure_file(
                "${_aw_daemon_impl}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.cpp"
                @ONLY
            )
            target_sources(${TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_daemon.cpp")
        endif()

        # --- systemd .service unit file ---
        set(_aw_service_unit "${_aw_service_dir}/skeletons/service/posix/myapp.service.in")
        if(EXISTS "${_aw_service_unit}")
            configure_file(
                "${_aw_service_unit}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service"
                @ONLY
            )
        endif()
    endif()

    # -------------------------------------------------------------------
    # 9. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})

    # -------------------------------------------------------------------
    # 10. Install rules
    # -------------------------------------------------------------------
    include(GNUInstallDirs)

    # Install the binary.
    install(TARGETS ${TARGET}
        RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
    )

    if(_aw_platform STREQUAL "windows")
        # Windows: install the install script to datarootdir/scripts/.
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat")
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/install_${TARGET}.bat"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/scripts/"
            )
        endif()
    else()
        # Linux: install the .service unit file to systemd directory.
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service")
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.service"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/systemd/system/"
            )
        endif()
    endif()
endfunction()
