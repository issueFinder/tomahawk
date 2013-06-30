include( CMakeParseArguments )

function(tomahawk_add_library)
    # parse arguments (name needs to be saved before passing ARGN into the macro)
    set(NAME ${ARGV0})
    set(options NO_INSTALL NO_VERSION)
    set(oneValueArgs NAME TYPE EXPORT_MACRO TARGET TARGET_TYPE EXPORT VERSION SOVERSION)
    set(multiValueArgs SOURCES UI LINK_LIBRARIES COMPILE_DEFINITIONS)
    cmake_parse_arguments(LIBRARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    set(LIBRARY_NAME ${NAME})


#     message("*** Arguments for ${LIBRARY_NAME}")
#     message("Sources: ${LIBRARY_SOURCES}")
#     message("Link libraries: ${LIBRARY_LINK_LIBRARIES}")
#     message("UI: ${LIBRARY_UI}")
#     message("TARGET_TYPE: ${LIBRARY_TARGET_TYPE}")
#     message("EXPORT_MACRO: ${LIBRARY_EXPORT_MACRO}")
#     message("NO_INSTALL: ${LIBRARY_NO_INSTALL}")

    set(target ${LIBRARY_NAME})

    # qt stuff
    include_directories(${CMAKE_CURRENT_LIST_DIR})
    include_directories(${CMAKE_CURRENT_BINARY_DIR})

    if(LIBRARY_UI)
        qt_wrap_ui(LIBRARY_UI_SOURCES ${LIBRARY_UI})
        list(APPEND LIBRARY_SOURCES ${LIBRARY_UI_SOURCES})
    endif()

    # add resources from current dir
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/resources.qrc")
        qt_add_resources(LIBRARY_RC_SOURCES "resources.qrc")
        list(APPEND LIBRARY_SOURCES ${LIBRARY_RC_SOURCES})
        unset(LIBRARY_RC_SOURCES)
    endif()

    # add target
    if(LIBRARY_TARGET_TYPE STREQUAL "STATIC")
        add_library(${target} STATIC ${LIBRARY_SOURCES})
    elseif(LIBRARY_TARGET_TYPE STREQUAL "MODULE")
        add_library(${target} MODULE ${LIBRARY_SOURCES})
    else() # default
        add_library(${target} SHARED ${LIBRARY_SOURCES})
    endif()

    # HACK: add qt modules - every lib should define its own set of modules
    qt5_use_modules(${target} Core Network Widgets Sql Xml DBus)


    # definitions - can this be moved into set_target_properties below?
    add_definitions(${QT_DEFINITIONS})
    set_target_properties(${target} PROPERTIES AUTOMOC TRUE)

    if(LIBRARY_EXPORT_MACRO)
        set_target_properties(${target} PROPERTIES COMPILE_DEFINITIONS ${LIBRARY_EXPORT_MACRO})
    endif()

    if(LIBRARY_COMPILE_DEFINITIONS)
        # Dear CMake, i hate you! Sincerely, domme
        # At least in CMake 2.8.8, you CANNOT set more than one COMPILE_DEFINITIONS value
        # only takes the first one if called multiple times or bails out with wrong number of arguments
        # when passing in a list, thus i redefine the export macro here in hope it won't mess up other targets
        add_definitions( "-D${LIBRARY_EXPORT_MACRO}" )

        set_target_properties(${target} PROPERTIES COMPILE_DEFINITIONS ${LIBRARY_COMPILE_DEFINITIONS})
    endif()

    # add link targets
    target_link_libraries(${target} ${TOMAHAWK_LIBRARIES})
    if(LIBRARY_LINK_LIBRARIES)
        target_link_libraries(${target} ${LIBRARY_LINK_LIBRARIES})
    endif()

    # add soversion
    if(NOT LIBRARY_NO_VERSION)
        set_target_properties(${target} PROPERTIES VERSION ${LIBRARY_VERSION})

        if(NOT LIBRARY_SOVERSION)
            set(LIBRARY_SOVERSION ${LIBRARY_VERSION})
        endif()

        set_target_properties(${target} PROPERTIES SOVERSION ${LIBRARY_SOVERSION})
    endif()

    # make installation optional, maybe useful for dummy plugins one day
    if(NOT LIBRARY_NO_INSTALL)
        include(GNUInstallDirs)
        if(NOT LIBRARY_EXPORT)
            install(TARGETS ${target} DESTINATION ${CMAKE_INSTALL_LIBDIR})
        else()
            install(TARGETS ${target} EXPORT ${LIBRARY_EXPORT} DESTINATION ${CMAKE_INSTALL_LIBDIR})
        endif()
    endif()
endfunction()
