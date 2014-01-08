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

find_package(Ruby)
find_program(YARD NAMES yard)
if (NOT YARD_FOUND)
    message(STATUS "did not find Yard, the Ruby packages won't generate documentation")
endif()
if (NOT RUBY_FOUND)
    MESSAGE(STATUS "Ruby library not found. Skipping Ruby parts for this package")
else()
    MESSAGE(STATUS "Ruby library found")
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

    # rock_ruby_test([testfile1] [testfile2]
    #   [WORKING_DIRECTORY workdir])
    #
    # Runs the given tests under minitest
    #
    # If no tests are given, will use the test/ subdirectory of the current
    # source directory.
    #
    # The default working directory is the current source directory
    function(ROCK_RUBY_TEST TARGET)
        set(workdir ${CMAKE_CURRENT_SOURCE_DIR})
        set(mode FILES)
        foreach(arg ${ARGN})
            if (arg STREQUAL "WORKING_DIRECTORY")
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

        add_test(NAME test-${TARGET}-ruby
            WORKING_DIRECTORY "${workdir}"
            COMMAND ${RUBY_EXECUTABLE} -rminitest/autorun -I${CMAKE_CURRENT_SOURCE_DIR} -I${CMAKE_CURRENT_BINARY_DIR} ${testfiles})
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

    EXECUTE_PROCESS(COMMAND ${RUBY_EXECUTABLE} -r rbconfig -e "puts RUBY_VERSION"
       OUTPUT_VARIABLE RUBY_VERSION)
    STRING(REPLACE "\n" "" RUBY_VERSION ${RUBY_VERSION})
    STRING(REGEX MATCH "^1\\.9" RUBY_19 ${RUBY_VERSION})
    STRING(REGEX MATCH "^1\\.9\\.1" RUBY_191 ${RUBY_VERSION})
    message(STATUS "found Ruby version ${RUBY_VERSION}")

    EXECUTE_PROCESS(COMMAND ${RUBY_EXECUTABLE} -r rbconfig -e "puts RbConfig::CONFIG['CFLAGS']"
       OUTPUT_VARIABLE RUBY_CFLAGS)
    STRING(REPLACE "\n" "" RUBY_CFLAGS ${RUBY_CFLAGS})

    function(ROCK_RUBY_EXTENSION target)
	INCLUDE_DIRECTORIES(${RUBY_INCLUDE_PATH})
        list(GET ${RUBY_INCLUDE_PATH} 0 rubylib_path)
	GET_FILENAME_COMPONENT(rubylib_path ${rubylib_path} PATH)
	LINK_DIRECTORIES(${rubylib_path})

        if (RUBY_191)
            add_definitions(-DRUBY_191)
        elseif (RUBY_19)
            add_definitions(-DRUBY_19)
        endif()

	SET_SOURCE_FILES_PROPERTIES(${ARGN} PROPERTIES COMPILE_FLAGS "${RUBY_CFLAGS}")
        rock_library_common(${target} MODULE ${ARGN})
        target_link_libraries(${target} ${RUBY_LIBRARY})

        STRING(REGEX MATCH "arm.*" ARCH ${CMAKE_SYSTEM_PROCESSOR})
        IF("${ARCH}" STREQUAL "")
            set_target_properties(${target} PROPERTIES
                LINK_FLAGS "-z noexecstack")
        ENDIF("${ARCH}" STREQUAL "")
	SET_TARGET_PROPERTIES(${target} PROPERTIES PREFIX "")
    endfunction()

    macro(ROCK_RUBY_RICE_EXTENSION target)
        find_package(Gem COMPONENTS rice)
        if (GEM_rice_FOUND)
            ROCK_RUBY_EXTENSION(${target} ${ARGN})
	    include_directories(${GEM_INCLUDE_DIRS})
	    target_link_libraries(${target} ${GEM_LIBRARIES})

	    install(TARGETS ${target} LIBRARY DESTINATION ${RUBY_EXTENSIONS_INSTALL_DIR})
            set(${target}_AVAILABLE TRUE)
        else()
            message(WARNING "cannot find the rice gem -- extension ${target} will not be available")
            set(${target}_AVAILABLE FALSE)
        endif()
    endmacro()
ENDIF(NOT RUBY_INCLUDE_PATH)

