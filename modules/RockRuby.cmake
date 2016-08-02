# This module finds the Ruby package and defines a ADD_RUBY_EXTENSION macro to
# build and install Ruby extensions
# Upon loading, it sets a RUBY_EXTENSIONS_AVAILABLE variable to true if Ruby
# extensions can be built.
#
# The ADD_RUBY_EXTENSION macro can be used as follows:
#  ADD_RUBY_EXTENSION(target_name source1 source2 source3 ...)
#
# The following example is specific to building extension using rice.
# Thus, rice needs to be installed. If the extension can be build,
# the <extension-name>_AVAILABLE will be set.
#
# include(RockRuby)
# set(SOURCES your_extension.cpp)
#
# rock_ruby_rice_extension(your_extension_ruby ${SOURCES})
# if(your_extension_ruby_AVAILABLE)
#  ...
#  do additional linking or testing
#  ...
# endif()
#
# 
# If installed to a target directory set the following to true to
# make it project specific
# set(RUBY_USE_PROJECT_INSTALL_PREFIX TRUE)
#

find_package(Ruby)
find_program(YARD NAMES yard)
if (NOT YARD_FOUND)
    message(STATUS "did not find Yard, the Ruby packages won't generate documentation")
endif()

# rock_add_ruby_package(NAME
#   [RUBY_FILES rubyfile.rb rubydir]
#   [EXT_PLAIN|EXT_RICE] extname file1 file2 file3
#   )
# 
# Sets up the necessary build/install steps to handle the Ruby library in
# the current source directory, integrating documentation generation as well as
# unit tests
#
# The RUBY_FILES parameters are the name of Ruby files or directories containing
# Ruby files that should be installed to form the Ruby part of the Ruby package.
#
# The EXT_* parameters must be given if there is an ext/ folder, to tell how
# each extension should be built (using plain Ruby or Rice). extname is the
# subdirectory of ext/ in which the extension code lies. The extension files
# are given to the extension directory
function(rock_add_ruby_package NAME)
    set(mode START)
    set(required OFF)
    set(quiet OFF)
    foreach(arg ${ARGN})
        if (arg STREQUAL "REQUIRED")
            set(required ON)
        elseif (arg STREQUAL "QUIET")
            set(quiet ON)
        elseif (arg STREQUAL "RUBY_FILES")
            set(mode RUBY_FILES)
        elseif (arg STREQUAL "EXT_PLAIN" OR arg STREQUAL "EXT_RICE")
            set(ext_type ${arg})
            set(mode EXT_NAME)
        elseif (mode STREQUAL "EXT_NAME")
            if (NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/ext/${arg}")
                message(FATAL_ERROR "rock_add_ruby_package: ${arg} was expected to be a subdirectory of ext/, but is not")
            endif()

            set(extname "${arg}")
            list(APPEND extension_names "${extname}")
            set(${extname}_TYPE "${ext_type}")
            set(mode EXT_FILES)
        elseif (mode STREQUAL "RUBY_FILES")
            list(APPEND pure_ruby_files "${arg}")
        elseif (mode STREQUAL "EXT_FILES")
            list(APPEND ${extname}_FILES "ext/${extname}/${arg}")
        else()
            message(FATAL_ERROR "rock_add_ruby_package: unexpected argument ${arg} in mode '${mode}'")
        endif()
    endforeach()

    set(${NAME}_AVAILABLE ON)
    if (NOT RUBY_FOUND)
        set(${NAME}_AVAILABLE OFF)
    endif()

    list(LENGTH extension_names has_extensions)
    if (${NAME}_AVAILABLE AND has_extensions)
        if (NOT RUBY_EXTENSIONS_AVAILABLE)
            message(STATUS "the Ruby target ${NAME} need to build a Ruby extension, but this is not available")
            set(${NAME}_AVAILABLE OFF)
        endif()
    endif()

    if (${NAME}_AVAILABLE)
        foreach(extname ${extension_names})
            if (${extname}_TYPE STREQUAL "EXT_PLAIN")
                rock_ruby_extension(${extname} ${${extname}_FILES})
            elseif (${extname}_TYPE STREQUAL "EXT_RICE")
                rock_ruby_rice_extension(${extname} ${${extname}_FILES})
                set(${NAME}_AVAILABLE ${${extname}_AVAILABLE})
            else()
                message(FATAL_ERROR "invalid extension type '${${extname}_TYPE}' for '${extname}', expected either EXT_PLAIN or EXT_RICE")
            endif()
        endforeach()
        rock_ruby_library(${NAME} ${pure_ruby_files})

        if (ROCK_TEST_ENABLED AND IS_DIRECTORY test)
            rock_ruby_test(${NAME})
        endif()

        if (YARD_EXECUTABLE)
            rock_ruby_doc(${NAME})
            rock_add_dummy_target_dependency(doc doc-${NAME}-ruby)
        endif()
    elseif (required)
        message(FATAL_ERROR "cannot build required Ruby target ${NAME}")
    elseif(NOT quiet)
        message(STATUS "ignoring Ruby target ${NAME}, Ruby and/or the Ruby extension building environment could not be found")
    endif()

    set(${NAME}_AVAILABLE ${${NAME}_AVAILABLE} PARENT_SCOPE)
endfunction()

if (NOT RUBY_FOUND)
    MESSAGE(STATUS "Ruby library not found. Skipping Ruby parts for this package")
else()
    MESSAGE(STATUS "Ruby library found: ${RUBY_LIBRARY}")
    function(ROCK_RUBY_LIBRARY libname)
        if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${libname}.rb)
            install(FILES ${libname}.rb
                DESTINATION ${RUBY_LIBRARY_INSTALL_DIR})
            list(REMOVE_ITEM ARGN ${libname}.rb)
        endif()
        if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${libname})
            install(DIRECTORY ${libname}
                DESTINATION ${RUBY_LIBRARY_INSTALL_DIR})
            list(REMOVE_ITEM ARGN ${libname})
        endif()

        if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/lib/${libname}.rb)
            install(FILES lib/${libname}.rb
                DESTINATION ${RUBY_LIBRARY_INSTALL_DIR})
            list(REMOVE_ITEM ARGN lib/${libname}.rb)
        endif()
        if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${libname})
            install(DIRECTORY lib/${libname}
                DESTINATION ${RUBY_LIBRARY_INSTALL_DIR})
            list(REMOVE_ITEM ARGN lib/${libname})
        endif()

        foreach(to_install ${ARGN})
            if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${to_install})
                install(DIRECTORY ${to_install}
                    DESTINATION ${RUBY_LIBRARY_INSTALL_DIR}/${libname})
            else()
                install(FILES ${to_install}
                    DESTINATION ${RUBY_LIBRARY_INSTALL_DIR}/${libname})
            endif()
        endforeach()
    endfunction()

    function(ROCK_LOG_MIGRATION)
        if (EXISTS ${CMAKE_SOURCE_DIR}/src/log_migration.rb)
            configure_file(${CMAKE_SOURCE_DIR}/src/log_migration.rb
                ${CMAKE_BINARY_DIR}/log_migration-${PROJECT_NAME}.rb COPYONLY)
            install(FILES ${CMAKE_BINARY_DIR}/log_migration-${PROJECT_NAME}.rb
                    DESTINATION share/rock/log/migration)
        endif()
    endfunction()

    function(ROCK_TYPELIB_RUBY_PLUGIN)
        install(FILES ${ARGN}
            DESTINATION share/typelib/ruby)
    endfunction()

    function(ROCK_LOG_EXPORT)
        if (EXISTS ${CMAKE_SOURCE_DIR}/src/log_export.rb)
            configure_file(${CMAKE_SOURCE_DIR}/src/log_export.rb
                ${CMAKE_BINARY_DIR}/log_export-${PROJECT_NAME}.rb COPYONLY)
            install(FILES ${CMAKE_BINARY_DIR}/log_export-${PROJECT_NAME}.rb
                    DESTINATION share/rock/log/export)
        endif()
    endfunction()

    # rock_ruby_doc(TARGET)
    #
    # Create a target called doc-${TARGET}-ruby that generates the documentation
    # for the Ruby package contained in the current directory, using Yard. The
    # documentation is generated in the build folder under doc/${TARGET}
    #
    # Add a .yardopts file in the root of the embedded ruby package to configure
    # Yard. See e.g. http://rubydoc.info/gems/yard/YARD/CLI/Yardoc. The output
    # directory is overriden when cmake calls yard
    function(rock_ruby_doc TARGET)
        add_custom_target(doc-${TARGET}-ruby
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            ${YARD_EXECUTABLE} doc -o ${PROJECT_BINARY_DIR}/doc/${TARGET})
    endfunction()

    # rock_ruby_test([FILES] testfile1 [testfile2]
    #   [WORKING_DIRECTORY workdir])
    #
    # Runs the given tests under minitest. The filenames following the FILES
    # statement are a list of files or directories that should be require'd to
    # run the tests. If directories are given, all files whose extension is 'rb'
    # are added, recursively.
    #
    # If no tests are given, will use the test/ subdirectory of the current
    # source directory.
    #
    # The default working directory is the current source directory.
    function(ROCK_RUBY_TEST TARGET)
        set(workdir ${CMAKE_CURRENT_SOURCE_DIR})
        set(mode FILES)
        foreach(arg ${ARGN})
            if (arg STREQUAL "FILES")
                set(mode FILES)
            elseif (arg STREQUAL "WORKING_DIRECTORY")
                set(mode WORKING_DIRECTORY)
            elseif (mode STREQUAL "WORKING_DIRECTORY")
                set(workdir "${arg}")
                set(mode "")
            elseif (mode STREQUAL "FILES")
                list(APPEND test_args "${arg}")
            else()
                message(FATAL_ERROR "trailing arguments ${arg} to rock_ruby_test")
            endif()
        endforeach()

        list(LENGTH test_args has_test_args)
        if (NOT has_test_args)
            if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/test)
                list(APPEND test_args "${CMAKE_CURRENT_SOURCE_DIR}/test")
            else()
                message(FATAL_ERROR "rock_ruby_test: called without test files, and there is no test/ folder")
            endif()
        endif()

        foreach(test_arg ${test_args})
            if (IS_DIRECTORY ${test_arg})
                file(GLOB_RECURSE dir_testfiles ${test_arg}/*.rb)
                list(APPEND testfiles ${dir_testfiles})
            else()
                list(APPEND testfiles ${test_arg})
            endif()
        endforeach()

        foreach(test_file ${testfiles})
            set(test_requires "${test_requires}require '${test_file}';")
        endforeach()

        add_test(NAME test-${TARGET}-ruby
            WORKING_DIRECTORY "${workdir}"
            COMMAND ${RUBY_EXECUTABLE} -rminitest/autorun -I${CMAKE_CURRENT_SOURCE_DIR}/lib -I${CMAKE_CURRENT_SOURCE_DIR} -I${CMAKE_CURRENT_BINARY_DIR} -e "${test_requires}")
    endfunction()
endif()

# The functions below are available only if we can build Ruby extensions
IF(NOT RUBY_INCLUDE_PATH)
    MESSAGE(STATUS "Ruby library not found. Cannot build Ruby extensions")
    SET(RUBY_EXTENSIONS_AVAILABLE FALSE)
ELSEIF(NOT RUBY_EXTENSIONS_AVAILABLE)
    SET(RUBY_EXTENSIONS_AVAILABLE TRUE)
    STRING(REGEX REPLACE ".*lib(32|64)?/?" "lib/" RUBY_EXTENSIONS_INSTALL_DIR ${RUBY_ARCH_DIR})
    STRING(REGEX REPLACE ".*lib(32|64)?/?" "lib/" RUBY_LIBRARY_INSTALL_DIR ${RUBY_RUBY_LIB_PATH})

    IF(RUBY_USE_PROJECT_INSTALL_PREFIX AND PROJECT_NAME)
        message(INFO "Install prefix for extensions is using project name: ${PROJECT_NAME}")
        set(RUBY_EXTENSIONS_INSTALL_DIR ${RUBY_EXTENSIONS_INSTALL_DIR}/${PROJECT_NAME})
        set(RUBY_LIBRARY_INSTALL_DIR ${RUBY_LIBRARY_INSTALL_DIR}/${PROJECT_NAME})
    ENDIF()

    EXECUTE_PROCESS(COMMAND ${RUBY_EXECUTABLE} -r rbconfig -e "puts RUBY_VERSION"
       OUTPUT_VARIABLE RUBY_VERSION)
    STRING(REPLACE "\n" "" RUBY_VERSION ${RUBY_VERSION})
    message(STATUS "found Ruby version ${RUBY_VERSION}")

    EXECUTE_PROCESS(COMMAND ${RUBY_EXECUTABLE} -r rbconfig -e "puts RbConfig::CONFIG['CFLAGS']"
       OUTPUT_VARIABLE RUBY_CFLAGS)
    STRING(REPLACE "\n" "" RUBY_CFLAGS ${RUBY_CFLAGS})

    if("${RUBY_CFLAGS}" MATCHES "-fstack-protector-strong")
        include(CheckCXXCompilerFlag)
        CHECK_CXX_COMPILER_FLAG("-fstack-protector-strong" COMPILER_SUPPORTS_SMASH_PROTECTION)
        if(NOT COMPILER_SUPPORTS_SMASH_PROTECTION)
            STRING(REPLACE "-fstack-protector-strong" "" RUBY_CFLAGS ${RUBY_CFLAGS})
        endif()
    endif()

    function(ROCK_RUBY_EXTENSION target)
	INCLUDE_DIRECTORIES(${RUBY_INCLUDE_PATH})
        list(GET ${RUBY_INCLUDE_PATH} 0 rubylib_path)
	GET_FILENAME_COMPONENT(rubylib_path ${rubylib_path} PATH)
	LINK_DIRECTORIES(${rubylib_path})

	SET_SOURCE_FILES_PROPERTIES(${ARGN} PROPERTIES COMPILE_FLAGS "${RUBY_CFLAGS}")
        rock_library_common(${target} MODULE ${ARGN})
        IF(APPLE)
            set_property(TARGET ${target} PROPERTY SUFFIX ".bundle")
        ENDIF(APPLE)
        target_link_libraries(${target} ${RUBY_LIBRARY})
        
        include(CheckCXXCompilerFlag)
        SET(CMAKE_REQUIRED_FLAGS "-Wl,-z,noexecstack")
        CHECK_CXX_COMPILER_FLAG("" COMPILER_SUPPORTS_NOEXEXSTACK)
        if(COMPILER_SUPPORTS_NOEXEXSTACK)
            set_target_properties(${target} PROPERTIES LINK_FLAGS "-Wl,-z,noexecstack")
        endif()

	SET_TARGET_PROPERTIES(${target} PROPERTIES PREFIX "")
    endfunction()

    macro(ROCK_RUBY_RICE_EXTENSION target)
        find_package(Gem COMPONENTS rice)
        # Fallback to preinstalled package
        if (NOT GEM_rice_FOUND)
            set(GEM_OS_PKG ON)
            find_package(Gem COMPONENTS rice)
        endif()

        if (NOT GEM_rice_FOUND)
            message(FATAL_ERROR "could not find rice, which is required for this package's Ruby bindings. Set BINDINGS_RUBY to OFF to disable building the bindings altogether.")
        endif()

        message(STATUS "Using rice library: ${GEM_LIBRARIES}")
        ROCK_RUBY_EXTENSION(${target} ${ARGN})
        include_directories(${GEM_INCLUDE_DIRS})
        target_link_libraries(${target} ${GEM_LIBRARIES})
        if(NOT RUBY_EXTENSIONS_INSTALL_DIR EQUAL "")
            message(STATUS "Ruby extension installation dir: ${RUBY_EXTENSIONS_INSTALL_DIR}")
            install(TARGETS ${target} LIBRARY DESTINATION ${RUBY_EXTENSIONS_INSTALL_DIR})
        endif()
        set(${target}_AVAILABLE TRUE)
    endmacro()
ENDIF(NOT RUBY_INCLUDE_PATH)

