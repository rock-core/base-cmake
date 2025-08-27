#
# Functions and macros easing the use of Rock.cmake with Qt, specifically
# building multiple versions of the same library/executable to work with
# different Qt versions.
#
# These do not search for Qt by themselves, use Rock.cmakes rock_find_qt4,
# rock_find_qt5 for that. Qt6 is not supported, yet.
#
# rock_qt_library
#   Adds libraries to the project
#
# rock_qt_executable
#   Adds executables to the project
#
# rock_qt_vizkit_plugin
#   Adds vizkit plugins to the project
#
# rock_qt_vizkit_widget
#   Adds vizkit widgets to the project
#
# The above all take the same arguments, that consist of option markers
# followed by values relevant to that option.
# Ex: (SOURCES source1.cpp source2.cpp LIBS lib1 lib2), where
#     SOURCES and LIBS are option markers
# The options can be specified in any order and values accumulate, except
# where noted otherwise.
#
# Defining target names:
#
#   TARGET_PREFIX prefix   The single value is a prefix used to build target
#                          names, by default appending -qt4, -qt5, -qt6
#
#   TARGET_QT4 target      The single value defines the target name to be used
#   TARGET_QT5 target      with Qt4, Qt5 or Qt6. These override any
#   TARGET_QT6 target      TARGET_PREFIX derived names where a TARGET_QT*
#                          option exist.
#
#   QT4_SUFFIX suffix      The single value defines the suffix to be used
#   QT5_SUFFIX suffix      for TARGET_PREFIX, DEPS*_QT, LIBS_QT and EXPORT_QT
#   QT6_SUFFIX suffix      with Qt4, Qt5, Qt6. DEFAULT to -qt4, -qt5 and -qt6.
#
# Limiting what is to be built and what is required:
#
#   REQUIRED_QT4          This marks the Qt4, Qt5 or Qt6 version of the target
#   REQUIRED_QT5          to be required, that is, the configuration fails when
#   REQUIRED_QT6          it cannot be built, even when MISSINGQTDEPS_NOBUILD
#                         is set. This overrides any previous matching NO_QT4,
#                         NO_QT5, NO_QT6 option
#
#   NO_QT4                Disables building the Qt4, Qt5, Qt6 version of the
#   NO_QT5                target. This overrides any previous matching
#   NO_QT6                REQUIRED_QT4, REQUIRED_QT5, REQUIRED_QT6 option
#
#   MISSINGQTDEPS_FATAL   Makes configuration fail if support for a version of
#                         Qt has been found but the target cannot be built for
#                         other missing dependencies. This overrides any
#                         previous MISSINGQTDEPS_NOBUILD. This is the DEFAULT.
#
#   MISSINGQTDEPS_NOBUILD Skips building any or all versions target if any of
#                         their dependencies cannot be found.
#
# Sources, Headers, MOC and UI
#
#   SOURCES               Sources to be compiled and linked. Values given for
#   SOURCES_QT4           the SOURCES option are used with all Qt versions,
#   SOURCES_QT5           while SOURCES_QT4, SOURCES_QT5, SOURCES_QT6 are only
#   SOURCES_QT6           used with the respective Qt version.
#
#   HEADERS               Headers to be installed. Values given for
#   HEADERS_QT4           the HEADERS option are used with all Qt versions,
#   HEADERS_QT5           while HEADERS_QT4, HEADERS_QT5, HEADERS_QT6 are only
#   HEADERS_QT6           used with the respective Qt version.
#
#   MOC                   Sources or headers to be processed through Qts meta
#   MOC_QT4               object compiler. Values given for the MOC option
#   MOC_QT5               are used with all Qt versions, while MOC_QT4,
#   MOC_QT6               MOC_QT5, MOC_QT6 are only used with the respective
#                         Qt version. There are differences between how Qts
#                         meta object compiler handles source files(.cpp/.cc).
#                         In Qt4, those would be parsed as is, while starting
#                         with Qt5, the meta object compiler instead tries to
#                         find the relevant header and parses that.
#
#   UI                    Ui description files to be processed through uic.
#   UI_QT4                Values given for the UI option are used with all
#   UI_QT5                Qt versions while UI_QT4, UI_QT5, UI_QT6 are only
#   UI_QT6                used with the respective Qt version.
#
# Dependencies
#
#   DEPS                  Lists the other targets from this CMake project
#   DEPS_QT4              against which this target should be linked.
#   DEPS_QT5              Values given for the DEPS option are used for all Qt
#   DEPS_QT6              versions, while DEPS_QT4, DEPS_QT5, DEPS_QT6 are only
#   DEPS_QT               used with the respective Qt version. Values given for
#                         DEPS_QT are automatically suffixed with -qt4, -qt5
#                         or -qt6 (unless overriden with QT4_SUFFIX, QT5_SUFFIX
#                         or QT6_SUFFIX)
#
#   DEPS_PKGCONFIG       List of pkg-config packages that the library depends
#   DEPS_PKGCONFIG_QT4   upon. The necessary link and compilation flags are
#   DEPS_PKGCONFIG_QT5   added to the target, the packages to the .pc file of
#   DEPS_PKGCONFIG_QT6   the target, if any. Values given for the
#   DEPS_PKGCONFIG_QT    DEPS_PKGCONFIG option are used for all Qt versions,
#                        while DEPS_PKGCONFIG_QT4, DEPS_PKGCONFIG_QT5,
#                        DEPS_PKGCONFIG_QT6 are only used with the respective
#                        Qt version. Values given for DEPS_PKGCONFIG_QT are
#                        automatically suffixed with -qt4, -qt5 or -qt6 (unless
#                        overriden with QT4_SUFFIX, QT5_SUFFIX or QT6_SUFFIX)
#
#   DEPS_CMAKE           List of packages which can be found with CMake's
#   DEPS_CMAKE_QT4       find_package, that the library depends upon. It is
#   DEPS_CMAKE_QT5       assumed that the Find*.cmake scripts follow the cmake
#   DEPS_CMAKE_QT6       accepted standard for variable naming. Values given
#   DEPS_CMAKE_QT        for the DEPS_CMAKE option are used for all Qt
#                        versions, while DEPS_CMAKE_QT4, DEPS_CMAKE_QT5,
#                        DEPS_CMAKE_QT6 are only used with the respective Qt
#                        version. Values given for DEPS_CMAKE_QT are
#                        automatically suffixed with -qt4, -qt5 or -qt6 (unless
#                        overriden with QT4_SUFFIX, QT5_SUFFIX or QT6_SUFFIX)
#
#   DEPS_TARGET          Lists the CMake imported targets which should be used
#   DEPS_TARGET_QT4      for this target. The targets must have been found
#   DEPS_TARGET_QT5      already using e.g. `find_package`. The libraries and
#   DEPS_TARGET_QT6      includes are added to the targets .pc file, if any.
#   DEPS_TARGET_QT       Values given for the DEPS_TARGET option are used for
#                        all Qt versions, while DEPS_TARGET_QT4,
#                        DEPS_TARGET_QT5, DEPS_TARGET_QT6 are only used with
#                        the respective Qt version. Values given for
#                        DEPS_TARGET_QT are automatically suffixed with -qt4,
#                        -qt5 or -qt6 (unless overriden with QT4_SUFFIX,
#                        QT5_SUFFIX or QT6_SUFFIX)
#
#   LIBS                 Cmake targets to be added via target_link_libraries.
#   LIBS_QT4             These are not explicitly inherited by other packages.
#   LIBS_QT5             Values given for the LIBS option are used for all Qt
#   LIBS_QT6             versions, while LIBS_QT4, LIBS_QT5, LIBS_QT6 are only
#   LIBS_QT              used with the respective Qt version. Values given for
#                        LIBS_QT are automatically suffixed with -qt4, -qt5 or
#                        -qt6 (unless overriden with QT4_SUFFIX, QT5_SUFFIX or
#                        QT6_SUFFIX)
#
#   DEPS_PLAIN           Same as DEPS_CMAKE, except it looks for fewer
#   DEPS_PLAIN_QT4       variables containing information about the package
#   DEPS_PLAIN_QT5       and does not try to find it. This is documented and
#   DEPS_PLAIN_QT6       supported here for completeness and backward
#   DEPS_PLAIN_QT        compatibility. DEPRECATED.
#
# Cmake target export:
#
#   EXPORT_QT4           A single value used with install(... EXPORT name).
#   EXPORT_QT5           EXPORT_QT4, EXPORT_QT5, EXPORT_QT6 give names
#   EXPORT_QT6           for individual Qt versions, EXPORT_QT defines a
#   EXPORT_QT            prefix. EXPORT should probably not be used, it
#   EXPORT               creates the same file for all Qt versions.
#                        This has no effect for executables, vizkit plugins and
#                        vizkit widgets.
#
# Various switches:
#
#   USE_BINARY_DIR       Whether the target needs to access headers from its
#   USE_BINARY_DIR_QT4   binary dir, as e.g. if some code-generated files are
#   USE_BINARY_DIR_QT5   used. This can also be set for individual Qt versions.
#   USE_BINARY_DIR_QT6
#
#   NOINSTALL            By default, the library gets installed on
#   NOINSTALL_QT4        'make install'. If this argument is given, this is
#   NOINSTALL_QT5        turned off.  This can also be set for individual Qt
#   NOINSTALL_QT6        versions.
#
#   LANG_C               Use this if the code is written in C. This can also be
#   LANG_C_QT4           set for individual Qt versions.
#   LANG_C_QT5
#   LANG_C_QT6
#
#
#

include(Rock)

cmake_policy(PUSH)
# this enables if(VAR STREQUAL "QUOTED") to interpret "QOUTED" as a string,
# even when a variable of the same name exists. OLD will dereference QOUTED,
# and use the result of that instead in the comparison, just like
# if(VAR STREQUAL UNQOUTED) would.
cmake_policy(SET CMP0054 NEW)

#
# INTERNAL
#
# Filters and prepares the argument lists so they can be used with
# rock_library and rock_executable
#
# TARGET_QT is QT4 QT5 QT6 etc
#
# There are no additional positional arguments. All other arguments must
# follow one of the following markers:
#
# QT<n>_SUFFIX <suffix>          can be defined to override the -qt<n> suffix
# TARGETPREFIX <targetprefix>    can only apply to exactly one argument, defines
#                                <targetprefix>-qt4, <targetprefix>-qt5,
#                                <targetprefix>-qt6 as targets for Qt4, Qt5 and
#                                Qt6.
# TARGET_<qt> <target>           can only apply to exactly one argument, defines
#                                <target> as target for <qt>
# MOC <headers, sources...>      Files to be passed to Qts moc
# MOC_<qt> <headers, sources...> Files only passed to moc for <qt>
# UI <uifiles...>                Files to be passed to Qts uic
# UI_<qt> <uifiles...>           Files only passed to uic for <qt>
#
#
# all other markers are either kept unchanged if they are not suffixed with
# one of _QT4, _QT5, _QT6 or _QT(for DEPS*).
# if they are suffixed with one of _QT4, _QT5, _QT6, they are only used with
# that qt version.
# if one of the DEPS* is suffixed with _QT, the targets are suffixed with
# -qtN as required.
#
# The understood markers are:
# SOURCES, USE_BINARY_DIR, DEPS, DEPS_PKGCONFIG, DEPS_TARGET, DEPS_CMAKE, LIBS
# HEADERS, NOINSTALL, LANG_C, EXPORT
#
# prepared lists are:
#
# for checking package presence:
#    DEPS_QT
#    DEPS_PKGCONFIG_QT
#    DEPS_TARGET_QT
#    DEPS_CMAKE_QT
#    LIBS_QT
#
# for writing messages:
#    TARGET
#
# for passing into rock_library/rock_executable
#    PREPARED_ARGS
#
function(rock_qt_filter_component_arguments QT_VER)
    #all toggles that can be suffixed with _QTx to only apply to that QT version
    set(TOGGLES "USE_BINARY_DIR;NOINSTALL;LANG_C")
    #all modes that can be used without suffix
    set(MODES "SOURCES;HEADERS;DEPS;DEPS_PKGCONFIG;DEPS_CMAKE;DEPS_PLAIN;DEPS_TARGET;MOC;UI;LIBS")
    #all modes that when suffixed with _QTx only apply to that QT version
    #must be a superset of MODES
    set(MODES_QTN "${MODES};TARGET;EXPORT")
    set(MODES_EXPORTED "${MODES};EXPORT")
    #all modes that can be suffixed with _QT to be auto-suffixed
    #must be a subset of MODES_QTN
    set(MODES_QT "DEPS;DEPS_PKGCONFIG;DEPS_CMAKE;DEPS_PLAIN;DEPS_TARGET;LIBS;EXPORT")
    #variables exported to the parent scope; these all are for checking dependencies, but
    #besides these, PREPARED_ARGS and TARGET are exported to parent scope.
    set(MODES_VARS "DEPS_QT;DEPS_PKGCONFIG_QT;DEPS_CMAKE_QT;DEPS_PLAIN_QT;DEPS_TARGET_QT;LIBS_QT")
    set(QTS QT4 QT5 QT6)
    set(CURRENTMODE BAD)

    if(QT_VER STREQUAL "QT4")
        set(QT_SUFFIX "-qt4")
    elseif(QT_VER STREQUAL "QT5")
        set(QT_SUFFIX "-qt5")
        set(REMAP_MOC MOC5)
        set(REMAP_UI UI5)
    elseif(QT_VER STREQUAL "QT6")
        set(QT_SUFFIX "-qt6")
        set(REMAP_MOC MOC6)
        set(REMAP_UI UI6)
    else()
        message(FATAL_ERROR "Dont know what suffix belongs to qt version ${QT_VER}")
    endif()

    set(PREPARED_ARGS)
    set(TARGET)
    foreach(MODE ${MODES_QTN})
        unset(${MODE}_QT)
    endforeach()

    foreach(MODE ${MODES_VARS})
        unset(${MODE})
    endforeach()

    foreach(MODE ${MODES_EXPORTED})
        unset(${MODE})
        unset(${MODE}_QT)
    endforeach()

    # we'll have to collect everything, change what needs changing and recreate
    # PREPARED_ARGS from that
    foreach(ELEMENT ${ARGN})
        set(IS_CONSUMED 0)

        # any modes that do not take a _QT* suffix
        if(ELEMENT STREQUAL "TARGETPREFIX")
            set(CURRENTMODE TARGETPREFIX)
            set(IS_CONSUMED 1)
        endif()
        # find toggles and modes that match mode_QTx
        foreach(SUFFIX ${QTS})
            if(SUFFIX STREQUAL QT_VER)
                if(ELEMENT STREQUAL "${SUFFIX}_SUFFIX")
                    set(QT_SUFFIX)
                    set(CURRENTMODE QT_SUFFIX)
                    set(IS_CONSUMED 1)
                endif()
                foreach(MODE ${MODES_QTN})
                    if(ELEMENT STREQUAL "${MODE}_${SUFFIX}")
                        set(CURRENTMODE "${MODE}_QTN")
                        set(IS_CONSUMED 1)
                    endif()
                endforeach()
                foreach(TOGGLE ${TOGGLES})
                    if(ELEMENT STREQUAL "${TOGGLE}_${SUFFIX}")
                        list(APPEND PREPARED_ARGS "${TOGGLE}")
                        set(IS_CONSUMED 1)
                        set(CURRENTMODE BAD)
                    endif()
                endforeach()
            else()
                if(ELEMENT STREQUAL "${SUFFIX}_SUFFIX")
                    set(CURRENTMODE IGNORE)
                    set(IS_CONSUMED 1)
                endif()
                foreach(MODE ${MODES_QTN})
                    if(ELEMENT STREQUAL "${MODE}_${SUFFIX}")
                        set(CURRENTMODE IGNORE)
                        set(IS_CONSUMED 1)
                    endif()
                endforeach()
                foreach(TOGGLE ${TOGGLES})
                    if(ELEMENT STREQUAL "${TOGGLE}_${SUFFIX}")
                        set(IS_CONSUMED 1)
                        set(CURRENTMODE BAD)
                    endif()
                endforeach()
            endif()
        endforeach()
        foreach(MODE ${MODES_QT})
            if(ELEMENT STREQUAL "${MODE}_QT")
                set(CURRENTMODE "${ELEMENT}")
                set(IS_CONSUMED 1)
            endif()
        endforeach()
        foreach(MODE ${MODES})
            if(ELEMENT STREQUAL MODE)
                set(CURRENTMODE "${ELEMENT}")
                set(IS_CONSUMED 1)
            endif()
        endforeach()
        foreach(TOGGLE ${TOGGLES})
            if(ELEMENT STREQUAL TOGGLE)
                list(APPEND PREPARED_ARGS "${TOGGLE}")
                set(IS_CONSUMED 1)
                set(CURRENTMODE BAD)
            endif()
        endforeach()

        if(NOT IS_CONSUMED)
            if(CURRENTMODE STREQUAL "BAD")
                message(FATAL_ERROR "Found element \"${ELEMENT}\" while there is no mode active")
            endif()

            if(NOT (CURRENTMODE STREQUAL "IGNORE"))
                list(APPEND ${CURRENTMODE} ${ELEMENT})
            endif()
        endif()
    endforeach()

    # build ${MODE}_QT
    foreach(MODE ${MODES_QT})
        unset(TMP)
        foreach(ELEM ${${MODE}_QT})
            list(APPEND TMP "${ELEM}${QT_SUFFIX}")
        endforeach()
        set(${MODE}_QT ${TMP})
    endforeach()

    foreach(MODE ${MODES_QTN})
        list(APPEND ${MODE}_QT ${${MODE}_QTN})
    endforeach()

    foreach(MODE ${MODES_VARS})
        set(${MODE} ${${MODE}} PARENT_SCOPE)
    endforeach()

    # put everything back together
    foreach(MODE ${MODES_EXPORTED})
        if(DEFINED ${MODE} OR DEFINED ${MODE}_QT)
            if(DEFINED REMAP_${MODE})
                list(APPEND PREPARED_ARGS ${REMAP_${MODE}} ${${MODE}} ${${MODE}_QT})
            else()
                list(APPEND PREPARED_ARGS ${MODE} ${${MODE}} ${${MODE}_QT})
            endif()
        endif()
    endforeach()

    if(DEFINED TARGET_QTN)
        set(TARGET ${TARGET_QTN})
    else()
        set(TARGET "${TARGETPREFIX}${QT_SUFFIX}")
    endif()

    list(PREPEND PREPARED_ARGS ${TARGET})

    set(PREPARED_ARGS ${PREPARED_ARGS} PARENT_SCOPE)
    set(TARGET ${TARGET} PARENT_SCOPE)
endfunction()

#
# INTERNAL
#
# checks if all qt dependencies are present
#
# check DEPS*_QT and LIBS_QT if all packages are present
#
# populates QTDEPS_MISSING with the missing dependencies
#
function(rock_qt_check_dependencies)
    unset(QTDEPS_MISSING)
    foreach(DEP ${DEPS_QT} ${LIBS_QT})
        if(NOT TARGET ${DEP} AND NOT ${DEP}_FOUND)
            list(APPEND QTDEPS_MISSING ${DEP})
        endif()
    endforeach()
    foreach(DEP  ${DEPS_TARGET_QT})
        if(NOT TARGET ${DEP})
            list(APPEND QTDEPS_MISSING ${DEP})
        endif()
    endforeach()
    foreach(DEP  ${DEPS_PKGCONFIG_QT})
        #check if we already found it or Rock.cmake already found it for us
        if((NOT ${DEP}_PKGCONFIG_FOUND) AND (NOT ${DEP}_QTPKGCONFIG_FOUND))
            #different name here, else we confuse Rock.cmake
            #probably because something leaks over, probably
            #some cached variable that is different between
            #here and there.
            pkg_check_modules(${DEP}_QTPKGCONFIG ${DEP})
            if(NOT ${DEP}_QTPKGCONFIG_FOUND)
                list(APPEND QTDEPS_MISSING ${DEP})
            endif()
        endif()
    endforeach()
    foreach(DEP  ${DEPS_CMAKE_QT})
        if(NOT ${DEP}_FOUND)
            find_package(${DEP})
            if(NOT ${DEP}_FOUND)
                list(APPEND QTDEPS_MISSING ${DEP})
            endif()
        endif()
    endforeach()
    set(QTDEPS_MISSING ${QTDEPS_MISSING} PARENT_SCOPE)
endfunction()

#
# INTERNAL
#
# Filters the ARGN for REQUIRED_*, NO_*, MISSINGQTDEPS_* and sets variables
# for each of them. Checks for Qt versions and dependencies of each of
# the targets versions to determine what needs to be built.
# Sets PREPARED_ARGS_QT4, PREPARED_ARGS_QT5, PREPARED_ARGS_QT6 if
# the given version has no missing dependencies and should be built.
# May send FATAL_ERROR if the Required Qt versions are not present or
# dependencies are missing.
#
macro(rock_qt_common)
    # filter REQUIRED_QTn, MISSINGQTDEPS*
    set(MISSINGQTDEPS_FATAL ON)
    set(REQUIRED_QT4 OFF)
    set(REQUIRED_QT5 OFF)
    set(REQUIRED_QT6 OFF)
    set(NO_QT4 OFF)
    set(NO_QT5 OFF)
    set(NO_QT6 OFF)
    set(args)
    foreach(ELEMENT ${ARGN})
        if(ELEMENT STREQUAL "REQUIRED_QT4")
            set(REQUIRED_QT4 ON)
            set(NO_QT4 OFF)
        elseif(ELEMENT STREQUAL "REQUIRED_QT5")
            set(REQUIRED_QT5 ON)
            set(NO_QT5 OFF)
        elseif(ELEMENT STREQUAL "REQUIRED_QT6")
            set(REQUIRED_QT6 ON)
            set(NO_QT6 OFF)
        elseif(ELEMENT STREQUAL "NO_QT4")
            set(NO_QT4 ON)
            set(REQUIRED_QT4 OFF)
        elseif(ELEMENT STREQUAL "NO_QT5")
            set(NO_QT5 ON)
            set(REQUIRED_QT5 OFF)
        elseif(ELEMENT STREQUAL "NO_QT6")
            set(NO_QT6 ON)
            set(REQUIRED_QT6 OFF)
        elseif(ELEMENT STREQUAL "MISSINGQTDEPS_FATAL")
            set(MISSINGQTDEPS_FATAL ON)
        elseif(ELEMENT STREQUAL "MISSINGQTDEPS_NOBUILD")
            set(MISSINGQTDEPS_FATAL OFF)
        else()
            list(APPEND args ${ELEMENT})
        endif()
    endforeach()
    foreach(QT_VER 4 5 6)
        unset(PREPARED_ARGS_QT${QT_VER})
        if(NOT ROCK_QT_VERSION_${QT_VER})
            if(REQUIRED_QT${QT_VER})
                rock_qt_filter_component_arguments(QT${QT_VER} ${args})
                message(FATAL_ERROR "${TARGET} cannot be built: missing Qt${QT_VER}")
            endif()
        else()
            if(NOT NO_QT${QT_VER})
                rock_qt_filter_component_arguments(QT${QT_VER} ${args})
                unset(QTDEPS_MISSING)
                rock_qt_check_dependencies()
                if(QTDEPS_MISSING)
                    if(REQUIRED_QT5 OR MISSINGQTDEPS_FATAL)
                        message(FATAL_ERROR "${TARGET} cannot be built: missing some dependencies: ${QTDEPS_MISSING}")
                    else()
                        message(WARNING "${TARGET} cannot be built: missing some dependencies: ${QTDEPS_MISSING}")
                    endif()
                else()
                    set(PREPARED_ARGS_QT${QT_VER} ${PREPARED_ARGS})
                    set(TARGET_NAME_QT${QT_VER} ${TARGET})
                endif()
            endif()
        endif()
    endforeach()
endmacro()

#
#
#
#
#
function(rock_qt_library)
    rock_qt_common(${ARGN})
    foreach(QT_VER QT4 QT5 QT6)
        if(DEFINED PREPARED_ARGS_${QT_VER})
            rock_library(${PREPARED_ARGS_${QT_VER}})
        endif()
    endforeach()
endfunction()

function(rock_qt_executable)
    rock_qt_common(${ARGN})
    foreach(QT_VER QT4 QT5 QT6)
        if(DEFINED PREPARED_ARGS_${QT_VER})
            rock_executable(${PREPARED_ARGS_${QT_VER}})
        endif()
    endforeach()
endfunction()

function(rock_qt_vizkit_plugin)
    unset(additional_deps)
    if (PROJECT_NAME STREQUAL "vizkit3d")
        # vizkit3d provides the library and uses its own target
    else()
        list(APPEND additional_deps DEPS_PKGCONFIG_QT4 vizkit3d
            DEPS_PKGCONFIG_QT5 vizkit3d-qt5)
    endif()
    rock_qt_common(${ARGN} ${additional_deps})

    foreach(QT_VER QT4 QT5 QT6)
        if(DEFINED PREPARED_ARGS_${QT_VER})
            rock_library_common(${PREPARED_ARGS_${QT_VER}})
            if (${TARGET_NAME_${QT_VER}}_INSTALL)
                if (${TARGET_NAME_${QT_VER}}_LIBRARY_HAS_TARGET)
                    install(TARGETS ${TARGET_NAME_${QT_VER}}
                        LIBRARY DESTINATION lib)
                endif()
                install(FILES ${${TARGET_NAME_${QT_VER}}_HEADERS}
                    DESTINATION include/vizkit3d)
            endif()
        endif()
    endforeach()
endfunction()

function(rock_qt_vizkit_widget)
    rock_qt_common(${ARGN})

    foreach(QT_VER QT4 QT5 QT6)
        if(DEFINED PREPARED_ARGS_${QT_VER})
            rock_library_common(${PREPARED_ARGS_${QT_VER}})
            if (${TARGET_NAME_${QT_VER}}_INSTALL)
                install(TARGETS ${TARGET_NAME_${QT_VER}}
                    LIBRARY DESTINATION lib/qt/designer)
                install(FILES ${${TARGET_NAME_${QT_VER}}_HEADERS}
                    DESTINATION include/${PROJECT_NAME})
            endif()
        endif()
    endforeach()
    if(DEFINED PREPARED_ARGS_QT4)
        install(FILES ${TARGET_NAME_QT4}.rb
            DESTINATION share/vizkit/ext
            OPTIONAL)
        install(FILES vizkit_widget.rb
            DESTINATION lib/qt/designer/cplusplus_extensions
            RENAME ${PROJECT_NAME}_vizkit.rb
            OPTIONAL)
    endif()
endfunction()

cmake_policy(POP)
