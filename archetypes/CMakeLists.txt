# Archetype helpers — loaded by root CMakeLists.txt.
# Each file defines one or two aw_add_* functions for a specific build
# archetype.  Full implementations are deferred to Tasks 02–07.

include("${CMAKE_CURRENT_LIST_DIR}/01_core.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/02_shared_plugin.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/03_modules.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/04_executables.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/05_service.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/06_kernel.cmake")
