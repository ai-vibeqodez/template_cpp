#pragma once

/**
 * @file export_macro.hpp
 * @brief Cross-platform DLL export/import visibility macro.
 */

#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef __PROJECT_UPPER___BUILDING
        #define AW_API __declspec(dllexport)
    #else
        #define AW_API __declspec(dllimport)
    #endif
    #define AW_API_LOCAL
#else
    #if __GNUC__ >= 4
        #define AW_API __attribute__((visibility("default")))
        #define AW_API_LOCAL __attribute__((visibility("hidden")))
    #else
        #define AW_API
        #define AW_API_LOCAL
    #endif
#endif
