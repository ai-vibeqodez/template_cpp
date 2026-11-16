# aw_install_library()
#
# Install rules + export targets + CMake package config files.
#
# Usage:
#   include(cmake/Library/InstallExport)
#   aw_install_library(NAME MyLib NS aw:: EXPORT_NAME mylib)
#
# Requires: GNUInstallDirs, CMakePackageConfigHelpers (included internally)
# Depends on: CMAKE_CURRENT_BINARY_DIR, CMAKE_CURRENT_SOURCE_DIR, PROJECT_VERSION

function(aw_install_library)
    set(_oneValue NAME NS EXPORT_NAME)
    set(_multiValue)
    cmake_parse_arguments(_INST "${_multiValue}" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _INST_NAME)
        message(FATAL_ERROR "aw_install_library() requires NAME argument")
    endif()
    if(NOT _INST_NS)
        message(FATAL_ERROR "aw_install_library() requires NS argument")
    endif()

    if(NOT _INST_EXPORT_NAME)
        set(_INST_EXPORT_NAME ${_INST_NAME})
    endif()

    include(GNUInstallDirs)
    include(CMakePackageConfigHelpers)

    # --- Install targets ---
    # CMake 3.23+ supports FILE_SET HEADERS (preferred);
    # for older versions fall back to target_include_directories.
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.23)
        install(TARGETS ${_INST_NAME}
            EXPORT ${_INST_EXPORT_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            FILE_SET HEADERS DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
    else()
        install(TARGETS ${_INST_NAME}
            EXPORT ${_INST_EXPORT_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        )
    endif()

    # --- Install export ---
    install(EXPORT ${_INST_EXPORT_NAME}Targets
        FILE ${_INST_EXPORT_NAME}Targets.cmake
        NAMESPACE ${_INST_NS}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_INST_NAME}
    )

    # --- Version file ---
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${_INST_EXPORT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # --- Config file (generated) ---
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${_INST_EXPORT_NAME}Config.cmake"
        "include(CMakeFindDependencyMacro)\n"
        "include(\"\${CMAKE_CURRENT_LIST_DIR}/${_INST_EXPORT_NAME}Targets.cmake\")\n"
    )

    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${_INST_EXPORT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${_INST_EXPORT_NAME}ConfigVersion.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_INST_NAME}
    )
endfunction()
