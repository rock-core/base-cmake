set(SISL_FOUND FALSE)

if (NOT SISL_PREFIX)
    set(SISL_PREFIX ${CMAKE_INSTALL_PREFIX} CACHE FILEPATH "the installation prefix for the SISL library")
endif()

find_package(PkgConfig)
pkg_check_modules(PC_SISL QUIET base-types-sisl)
set(SISL_DEFINITIONS ${PC_SISL_CFLAGS_OTHER})

find_path(SISL_INCLUDE_DIRS "sisl.h"
    HINTS ${SISL_PREFIX}/include ${CMAKE_INSTALL_PREFIX}/include ${PC_SISL_INCLUDEDIR} ${PC_SISL_INCLUDE_DIRS})
find_library(SISL_LIBRARIES
    NAMES libsisl${CMAKE_SHARED_LIBRARY_SUFFIX} libsisl_opt${CMAKE_SHARED_LIBRARY_SUFFIX} libsisl.a libsisl_opt.a
    HINTS ${SISL_PREFIX}/lib ${CMAKE_INSTALL_PREFIX}/lib ${PC_SISL_LIBDIR} ${PC_SISL_LIBRARY_DIRS})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SISL "SISL library not found, NURBS 3D curve wrappers won't be installed" SISL_INCLUDE_DIRS SISL_LIBRARIES)
