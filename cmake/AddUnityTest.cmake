function(add_unity_test TEST_NAME)
    # Directory of the calling CMakeLists.txt
    set(CALLER_DIR "${CMAKE_CURRENT_LIST_DIR}")

    # All remaining arguments are sources
    set(TEST_SRCS ${ARGN})
    if(TEST_SRCS STREQUAL "")
        message(FATAL_ERROR "add_unity_test requires at least one source file")
    endif()

    # First source is the test file (for runner)
    list(GET TEST_SRCS 0 TEST_FILE)

    # Resolve absolute path for test file
    if(NOT IS_ABSOLUTE "${TEST_FILE}")
        get_filename_component(TEST_FILE_ABS "${TEST_FILE}" ABSOLUTE BASE_DIR "${CALLER_DIR}")
    else()
        set(TEST_FILE_ABS "${TEST_FILE}")
    endif()

    # Detect if any test sources are C++ files; if so generate a .cpp runner
    set(TEST_RUNNER_EXT ".c")
    foreach(SRC ${TEST_SRCS})
        get_filename_component(_ext "${SRC}" EXT)
        if(_ext STREQUAL ".cpp" OR _ext STREQUAL ".cxx" OR _ext STREQUAL ".cc")
            set(TEST_RUNNER_EXT ".cpp")
            break()
        endif()
    endforeach()
    set(TEST_RUNNER "${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}_runner${TEST_RUNNER_EXT}")
	if(NOT DEFINED UNITY_AUTO_DIR)
	    if(DEFINED unity_SOURCE_DIR)
	        set(UNITY_AUTO_DIR "${unity_SOURCE_DIR}/auto")
	    else()
	        message(FATAL_ERROR "UNITY_AUTO_DIR not set and unity_SOURCE_DIR missing")
	    endif()
	endif()
    add_custom_command(
        OUTPUT ${TEST_RUNNER}
        COMMAND ruby "${UNITY_AUTO_DIR}/generate_test_runner.rb"
                "${TEST_FILE_ABS}" "${TEST_RUNNER}"
        DEPENDS ${TEST_FILE_ABS}
        COMMENT "Generating Unity test runner for ${TEST_FILE_ABS}"
        BYPRODUCTS ${TEST_RUNNER}
    )

    # Resolve all sources relative to the caller dir
    set(ALL_SRCS "")
    foreach(SRC ${TEST_SRCS})
        if(NOT IS_ABSOLUTE "${SRC}")
            get_filename_component(SRC_ABS "${SRC}" ABSOLUTE BASE_DIR "${CALLER_DIR}")
        else()
            set(SRC_ABS "${SRC}")
        endif()
        list(APPEND ALL_SRCS ${SRC_ABS})
    endforeach()

    add_executable(${TEST_NAME} ${ALL_SRCS})
    target_link_libraries(${TEST_NAME} PRIVATE unity::framework)
    target_sources(${TEST_NAME} PRIVATE ${TEST_RUNNER})
    add_custom_target(${TEST_NAME}_runner_gen DEPENDS ${TEST_RUNNER})
    add_dependencies(${TEST_NAME} ${TEST_NAME}_runner_gen)
    target_compile_definitions(${TEST_NAME} PRIVATE UNITY_INCLUDE_DOUBLE)
    if(MSVC)
        target_compile_options(${TEST_NAME} PRIVATE /wd5045)
    endif()
    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME})
endfunction()
