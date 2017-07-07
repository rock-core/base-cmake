cmake_minimum_required(VERSION 2.6)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/modules")
include(${CMAKE_CURRENT_SOURCE_DIR}/modules/Rock.cmake)
rock_init(cmake 1.0)

install(FILES
    modules/FindGem.cmake
    modules/FindNumpy.cmake
    modules/FindRuby.cmake
    modules/FindSISL.cmake
    modules/ListMacros.cmake
    modules/PythonBind.cmake
    modules/PythonInstallPath.cmake
    modules/Rock.cmake
    modules/RockRuby.cmake
    modules/rock-config.cmake
    DESTINATION share/rock/cmake)

