# =============================================================================
# 06_kernel.cmake — Kernel driver archetype
#
# Provides:
#   aw_add_kernel_driver()  — Kernel-mode driver (Windows WDK .sys, Linux .ko)
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.
set(_aw_kernel_dir "${CMAKE_CURRENT_LIST_DIR}")

# ===========================================================================
# aw_add_kernel_driver()
#
# Create a kernel-mode driver target:
#   - Windows: Builds a .sys driver using the WDK (cl.exe with /kernel).
#   - Linux:   Builds a .ko loadable kernel module via Kbuild (make -C
#              <kernel_src> M=<build_dir> modules).
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required; typically .c).
#   HEADERS <files>...           Kernel header files (optional; typically .h).
#   PLATFORM <windows|linux|auto>
#                                Target platform. Default: auto.
#   WDK_VERSION <10.0|11.0>      Windows WDK version (default: 10.0).
#   LINUX_VERSION <6.1|6.6>      Minimum Linux kernel version (default: 6.1).
#   MODULE_NAME <name>           Linux module name (default: derived from TARGET).
#   KERNEL_SRC_DIR <path>        Path to Linux kernel source tree (Linux).
#   WDK_DIR <path>               Path to WDK installation (Windows).
#
# Example:
#   aw_add_kernel_driver(TARGET my_driver
#       SOURCES src/driver.c
#       HEADERS include/driver.h
#       PLATFORM windows
#       WDK_VERSION 10.0
#   )
#
#   aw_add_kernel_driver(TARGET my_module
#       SOURCES src/module.c
#       PLATFORM linux
#       LINUX_VERSION 6.6
#       KERNEL_SRC_DIR /lib/modules/$(uname -r)/build
#   )
# ===========================================================================
function(aw_add_kernel_driver TARGET)
    cmake_parse_arguments(ARG
        ""
        "PLATFORM;WDK_VERSION;LINUX_VERSION;MODULE_NAME;KERNEL_SRC_DIR;WDK_DIR"
        "SOURCES;HEADERS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT TARGET)
        message(FATAL_ERROR
            "aw_add_kernel_driver(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_kernel_driver(${TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_PLATFORM)
        set(ARG_PLATFORM "auto")
    endif()

    if(NOT ARG_WDK_VERSION)
        set(ARG_WDK_VERSION "10.0")
    endif()

    if(NOT ARG_LINUX_VERSION)
        set(ARG_LINUX_VERSION "6.1")
    endif()

    if(NOT ARG_MODULE_NAME)
        set(ARG_MODULE_NAME "${TARGET}")
    endif()

    # -------------------------------------------------------------------
    # 2. Detect platform
    # -------------------------------------------------------------------
    if(ARG_PLATFORM STREQUAL "auto")
        if(CMAKE_SYSTEM_NAME MATCHES "Windows")
            set(_aw_platform "windows")
        elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
            set(_aw_platform "linux")
        else()
            message(FATAL_ERROR
                "aw_add_kernel_driver(${TARGET}): "
                "Cannot auto-detect platform on ${CMAKE_SYSTEM_NAME}. "
                "Specify PLATFORM windows or PLATFORM linux.")
        endif()
    elseif(ARG_PLATFORM STREQUAL "windows")
        set(_aw_platform "windows")
    elseif(ARG_PLATFORM STREQUAL "linux")
        set(_aw_platform "linux")
    else()
        message(FATAL_ERROR
            "aw_add_kernel_driver(${TARGET}): "
            "PLATFORM must be 'windows', 'linux', or 'auto'")
    endif()

    # -------------------------------------------------------------------
    # 3. Create target
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # Windows WDK: use add_executable with no subsystem (produces .sys).
        add_executable(${TARGET} ${ARG_SOURCES})
    else()
        # Linux: create an INTERFACE library as a marker; the actual build
        # happens via Kbuild in a custom command.
        add_library(${TARGET} INTERFACE)
    endif()

    # No ALIAS target — kernel drivers are not imported by other projects.

    # -------------------------------------------------------------------
    # 4. Common compile features & definitions
    # -------------------------------------------------------------------
    target_compile_definitions(${TARGET} PRIVATE
        _KERNEL_MODE
        __KERNEL__
    )

    target_include_directories(${TARGET} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )

    if(ARG_HEADERS)
        target_include_directories(${TARGET} PRIVATE
            ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 5. Platform-specific configuration
    # -------------------------------------------------------------------
    if(_aw_platform STREQUAL "windows")
        # ------- Windows WDK flags -------
        if(NOT MSVC)
            message(WARNING
                "aw_add_kernel_driver(${TARGET}): "
                "Windows kernel drivers require the MSVC compiler (cl.exe). "
                "Ensure the WDK toolchain is configured.")
        endif()

        target_compile_options(${TARGET} PRIVATE
            /kernel
            /W4
            /Zc:wchar_t
            /Zc:inline
            /permissive-
        )

        target_compile_definitions(${TARGET} PRIVATE
            UNICODE
            _UNICODE
            NTDDI_VERSION=0x0A00000F
            _WIN32_WINNT=0x0A00
        )

        # Link against WDK libraries.
        target_link_libraries(${TARGET} PRIVATE
            ntoskrnl.lib
            wdm.lib
            wdfldr.lib
        )

        if(ARG_WDK_DIR)
            set(_aw_wdk_dir "${ARG_WDK_DIR}")
            target_include_directories(${TARGET} PRIVATE
                "${_aw_wdk_dir}/Include/${ARG_WDK_VERSION}/km"
                "${_aw_wdk_dir}/Include/${ARG_WDK_VERSION}/shared"
            )
            target_link_directories(${TARGET} PRIVATE
                "${_aw_wdk_dir}/Lib/${ARG_WDK_VERSION}/km/x64"
            )
        endif()

        # No install rules — kernel drivers are deployed via specialized
        # mechanisms (inf files, signtool, etc.).

    else()
        # ------- Linux Kbuild configuration -------
        if(NOT ARG_KERNEL_SRC_DIR)
            # Try to detect kernel source from running kernel.
            find_program(_AW_UNAME uname)
            if(_AW_UNAME)
                execute_process(
                    COMMAND ${_AW_UNAME} -r
                    OUTPUT_VARIABLE _AW_KERN_REL
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE _AW_UNAME_RC
                )
                if(_AW_UNAME_RC EQUAL 0 AND _AW_KERN_REL)
                    set(ARG_KERNEL_SRC_DIR
                        "/lib/modules/${_AW_KERN_REL}/build")
                endif()
            endif()
            unset(_AW_UNAME)
            unset(_AW_KERN_REL)
            unset(_AW_UNAME_RC)
        endif()

        if(NOT ARG_KERNEL_SRC_DIR)
            message(WARNING
                "aw_add_kernel_driver(${TARGET}): "
                "KERNEL_SRC_DIR not specified and could not auto-detect. "
                "Set KERNEL_SRC_DIR to your kernel source or headers path.")
            set(ARG_KERNEL_SRC_DIR "/usr/src/linux-headers-$(uname -r)/build")
        endif()

        # Generate Kbuild file.
        set(_aw_kbuild_in
            "${_aw_kernel_dir}/skeletons/kernel/linux/Kbuild.in")
        set(_aw_kbuild_out
            "${CMAKE_CURRENT_BINARY_DIR}/Kbuild")

        if(EXISTS "${_aw_kbuild_in}")
            configure_file(
                "${_aw_kbuild_in}"
                "${_aw_kbuild_out}"
                @ONLY
            )
        else()
            message(FATAL_ERROR
                "aw_add_kernel_driver(${TARGET}): "
                "Kbuild.in skeleton not found at ${_aw_kbuild_in}")
        endif()

        # Generate the module source from skeleton.
        set(_aw_mod_in
            "${_aw_kernel_dir}/skeletons/kernel/linux/module.c.in")
        set(_aw_mod_out
            "${CMAKE_CURRENT_BINARY_DIR}/${ARG_MODULE_NAME}.c")

        if(EXISTS "${_aw_mod_in}")
            configure_file(
                "${_aw_mod_in}"
                "${_aw_mod_out}"
                @ONLY
            )
        endif()

        # Custom target to invoke Kbuild.
        add_custom_target(${TARGET}_build
            COMMAND ${CMAKE_MAKE_PROGRAM}
                -C "${ARG_KERNEL_SRC_DIR}"
                M=${CMAKE_CURRENT_BINARY_DIR}
                modules
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
            COMMENT "Building Linux kernel module ${TARGET}"
            DEPENDS "${_aw_kbuild_out}"
        )

        # Install the .ko module.
        install(FILES "${_aw_mod_out}"
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/modules/${ARG_LINUX_VERSION}/extra/"
            RENAME "${ARG_MODULE_NAME}.ko"
        )
    endif()

    # -------------------------------------------------------------------
    # 6. Apply infrastructure helpers (warnings, sanitizers, coverage)
    #    Note: sanitizers and coverage are typically NOT useful for kernel
    #    drivers, but we keep the hooks for user-space testing targets.
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})

    # Kernel drivers should never have sanitizers or coverage enabled.
    # These helpers become no-ops for kernel targets if the user does not
    # explicitly set AW_..._SANITIZE or AW_..._ENABLE_COVERAGE.
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})

    # Lint is skipped for kernel drivers (clang-tidy does not understand
    # kernel headers).  aw_add_lint is intentionally NOT called here.
endfunction()
