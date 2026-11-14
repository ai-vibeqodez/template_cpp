# =============================================================================
# 04_executables.cmake — Executable and GUI application archetypes
#
# Provides:
#   aw_add_executable()          — Standard CLI executable with argument
#                                  parsing skeleton support.
#   aw_add_gui_executable()      — GUI executable with platform-specific
#                                  configuration (Win32 subsystem, macOS
#                                  .app bundle, Linux binary + desktop).
#
# =============================================================================

# Capture the directory where this .cmake file lives so skeleton paths are
# stable regardless of the calling context.
set(_aw_executables_dir "${CMAKE_CURRENT_LIST_DIR}")

# ===========================================================================
# aw_add_executable()
#
# Create a standard CLI executable target.  The resulting binary runs as a
# console application on all platforms.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_executable(TARGET my_cli
#       SOURCES src/my_cli.cpp
#       LINK_LIBRARIES aw::my_lib
#       COMPILE_DEFINITIONS MY_CLI_VERSION="1.0.0"
#   )
# ===========================================================================
function(aw_add_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "INSTALL_DESTINATION"
        "SOURCES;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_executable(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Create EXECUTABLE target (console subsystem on all platforms)
    # -------------------------------------------------------------------
    add_executable(${TARGET} ${ARG_SOURCES})

    # No ALIAS target — executables are not imported by other projects.

    # -------------------------------------------------------------------
    # 2. Compile features
    # -------------------------------------------------------------------
    target_compile_features(${TARGET} PUBLIC cxx_std_20)

    # -------------------------------------------------------------------
    # 3. Compile definitions
    # -------------------------------------------------------------------
    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 4. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 5. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${TARGET})
    _aw_apply_sanitizers(${TARGET})
    _aw_apply_coverage(${TARGET})
    aw_add_lint(${TARGET})

    # -------------------------------------------------------------------
    # 6. Install rules
    # -------------------------------------------------------------------
    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    include(GNUInstallDirs)
    install(TARGETS ${TARGET}
        RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
    )
endfunction()

# ===========================================================================
# aw_add_gui_executable()
#
# Create a GUI executable with platform-specific configuration:
#   - Windows: WIN32 subsystem (no console window, GUI entry point).
#   - macOS:   MACOSX_BUNDLE (.app bundle with Info.plist).
#   - Linux:   Standard binary; installs .desktop file and icon.
#
# Arguments:
#   TARGET <name>                Target name (required).
#   SOURCES <files>...           Source files (required).
#   HEADERS <files>...           Public header files (optional).
#   RESOURCES <files>...         Platform-specific resource files (e.g. .rc)
#                                (optional).
#   LINK_LIBRARIES <libs>...     Libraries to link against (optional).
#   COMPILE_DEFINITIONS <defs>   Compile definitions (optional).
#   APP_NAME <name>              Human-readable application name.
#                                Default: derived from TARGET.
#   APP_ICON <icon_file>         Platform-specific icon file (optional).
#   BUNDLE_ID <id>               macOS bundle identifier (reverse-DNS).
#                                Default: com.aw.<APP_NAME>.
#   APP_VERSION <version>        Application version string.
#                                Default: ${PROJECT_VERSION}.
#   INSTALL_DESTINATION <dir>    Install destination for the binary.
#                                Default: ${CMAKE_INSTALL_BINDIR}.
#
# Example:
#   aw_add_gui_executable(TARGET my_gui
#       SOURCES src/my_gui.cpp
#       RESOURCES src/icon.rc
#       APP_NAME "My GUI App"
#       APP_VERSION "1.0.0"
#       LINK_LIBRARIES aw::my_lib
#   )
# ===========================================================================
function(aw_add_gui_executable TARGET)
    cmake_parse_arguments(ARG
        ""
        "TARGET;INSTALL_DESTINATION;APP_NAME;APP_ICON;BUNDLE_ID;APP_VERSION"
        "SOURCES;HEADERS;RESOURCES;LINK_LIBRARIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    # -------------------------------------------------------------------
    # 0. Validate required arguments
    # -------------------------------------------------------------------
    if(NOT ARG_TARGET)
        message(FATAL_ERROR
            "aw_add_gui_executable(): "
            "TARGET is required")
    endif()

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR
            "aw_add_gui_executable(${ARG_TARGET}): "
            "SOURCES is required")
    endif()

    # -------------------------------------------------------------------
    # 1. Derive defaults
    # -------------------------------------------------------------------
    if(NOT ARG_APP_NAME)
        set(ARG_APP_NAME "${ARG_TARGET}")
    endif()

    if(NOT ARG_APP_VERSION)
        set(ARG_APP_VERSION "${PROJECT_VERSION}")
    endif()

    if(NOT ARG_BUNDLE_ID)
        set(ARG_BUNDLE_ID "com.aw.${ARG_APP_NAME}")
    endif()

    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()

    # -------------------------------------------------------------------
    # 2. Create target based on platform
    # -------------------------------------------------------------------
    if(WIN32)
        # Windows: WIN32 flag → GUI subsystem (no console window).
        add_executable(${ARG_TARGET} WIN32 ${ARG_SOURCES})

        # Include Win32 resource files if provided.
        if(ARG_RESOURCES)
            target_sources(${ARG_TARGET} PRIVATE ${ARG_RESOURCES})
        endif()

        # Include Win32 skeleton resource header if the user hasn't
        # provided their own.
        set(_aw_win_res_header "${ARG_TARGET}_resource.h")
        set(_aw_win_res_file "${_aw_executables_dir}/skeletons/gui/win32/resource.h.in")
        if(EXISTS "${_aw_win_res_file}")
            configure_file("${_aw_win_res_file}" "${CMAKE_CURRENT_BINARY_DIR}/${_aw_win_res_header}" COPYONLY)
            target_include_directories(${ARG_TARGET} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
        endif()

        # Generate the resource script from the skeleton if the user did
        # not supply one explicitly.
        if(NOT ARG_RESOURCES)
            set(_aw_win_rc_file "${_aw_executables_dir}/skeletons/gui/win32/icon.rc.in")
            if(EXISTS "${_aw_win_rc_file}")
                configure_file(
                    "${_aw_win_rc_file}"
                    "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_icon.rc"
                    @ONLY
                )
                target_sources(${ARG_TARGET} PRIVATE
                    "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_icon.rc")
            endif()
        endif()

    elseif(APPLE)
        # macOS: MACOSX_BUNDLE → .app bundle.
        add_executable(${ARG_TARGET} MACOSX_BUNDLE ${ARG_SOURCES})

        # Generate Info.plist from the skeleton.
        set(_aw_plist_file "${_aw_executables_dir}/skeletons/gui/macos/Info.plist.in")
        if(EXISTS "${_aw_plist_file}")
            configure_file(
                "${_aw_plist_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app/Contents/Info.plist"
                @ONLY
            )
            # Place the generated plist inside the bundle structure.
            set(_aw_plist_dest "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app/Contents/Info.plist")
            if(EXISTS "${_aw_plist_dest}")
                set_target_properties(${ARG_TARGET} PROPERTIES
                    MACOSX_BUNDLE_INFO_PLIST "${_aw_plist_dest}")
            endif()
        endif()

        # Include the Swift AppDelegate if the user hasn't provided
        # their own sources.
        set(_aw_swift_file "${_aw_executables_dir}/skeletons/gui/macos/AppDelegate.swift.in")
        if(EXISTS "${_aw_swift_file}")
            configure_file(
                "${_aw_swift_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_AppDelegate.swift"
                COPYONLY
            )
            target_sources(${ARG_TARGET} PRIVATE
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_AppDelegate.swift")
        endif()

    else()
        # Linux: standard executable, no subsystem flag.
        add_executable(${ARG_TARGET} ${ARG_SOURCES})

        # Install .desktop file and icon for desktop integration.
        set(_aw_desktop_file "${_aw_executables_dir}/skeletons/gui/linux/app.desktop.in")
        if(EXISTS "${_aw_desktop_file}")
            configure_file(
                "${_aw_desktop_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.desktop"
                @ONLY
            )
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.desktop"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications/"
            )
        endif()

        set(_aw_icon_file "${_aw_executables_dir}/skeletons/gui/linux/icons/symbolic.svg.in")
        if(EXISTS "${_aw_icon_file}")
            configure_file(
                "${_aw_icon_file}"
                "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}-symbolic.svg"
                @ONLY
            )
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}-symbolic.svg"
                DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps/"
            )
        endif()
    endif()

    # No ALIAS target — executables are not imported by other projects.

    # -------------------------------------------------------------------
    # 3. FILE_SET HEADERS (CMake 3.23+)
    # -------------------------------------------------------------------
    if(ARG_HEADERS)
        target_sources(${ARG_TARGET}
            PUBLIC
                FILE_SET HEADERS
                BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}
                FILES ${ARG_HEADERS}
        )
    endif()

    # -------------------------------------------------------------------
    # 4. Include directories
    # -------------------------------------------------------------------
    target_include_directories(${ARG_TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    # -------------------------------------------------------------------
    # 5. Compile features & definitions
    # -------------------------------------------------------------------
    target_compile_features(${ARG_TARGET} PUBLIC cxx_std_20)

    # Platform-specific compile definitions.
    if(WIN32)
        target_compile_definitions(${ARG_TARGET} PRIVATE WIN32_LEAN_AND_MEAN)
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${ARG_TARGET} PUBLIC ${ARG_COMPILE_DEFINITIONS})
    endif()

    # -------------------------------------------------------------------
    # 6. Link libraries
    # -------------------------------------------------------------------
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${ARG_TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
    endif()

    # -------------------------------------------------------------------
    # 7. Apply infrastructure helpers
    # -------------------------------------------------------------------
    _aw_set_warnings(${ARG_TARGET})
    _aw_apply_sanitizers(${ARG_TARGET})
    _aw_apply_coverage(${ARG_TARGET})
    aw_add_lint(${ARG_TARGET})

    # -------------------------------------------------------------------
    # 8. Install rules
    # -------------------------------------------------------------------
    include(GNUInstallDirs)

    if(APPLE)
        # macOS: install .app bundle to /Applications.
        install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.app"
            DESTINATION "Applications"
            COMPONENT Applications
        )
    else()
        # Windows / Linux: install binary to bindir.
        install(TARGETS ${ARG_TARGET}
            RUNTIME DESTINATION "${ARG_INSTALL_DESTINATION}"
        )
    endif()
endfunction()
