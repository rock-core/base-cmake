cmake_minimum_required(VERSION 2.6)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/Rock.cmake)
rock_init(cmake 1.0)

configure_file(cmake/rock-config.cmake.in rock-config.cmake @ONLY)
install(FILES
    cmake/FindBoost.cmake
    cmake/FindGem.cmake
    cmake/FindNumpy.cmake
    cmake/FindRuby.cmake
    cmake/FindSISL.cmake
    cmake/ListMacros.cmake
    cmake/PythonBind.cmake
    cmake/PythonInstallPath.cmake
    cmake/Rock.cmake
    cmake/RockRuby.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/rock-config.cmake
    DESTINATION share/rock/cmake)

