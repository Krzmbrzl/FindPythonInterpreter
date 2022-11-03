# Copyright 2021, Robert Adam. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# source tree.

cmake_minimum_required(VERSION 3.5)

function(find_python_interpreter)
	set(options REQUIRED EXACT)
	set(oneValueArgs VERSION INTERPRETER_OUT_VAR VERSION_OUT_VAR)
	set(multiValueArgs HINTS)
	cmake_parse_arguments(FIND_PYTHON_INTERPRETER "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})


	# Error handling
	if (FIND_PYTHON_INTERPRETER_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unrecognized arguments to find_python_interpreter: \"${FIND_PYTHON_INTERPRETER_UNPARSED_ARGUMENTS}\"")
	endif()
	if (NOT FIND_PYTHON_INTERPRETER_INTERPRETER_OUT_VAR)
		message(FATAL_ERROR "Called find_python_interpreter without the INTERPRETER_OUT_VAR parameter!")
	endif()
	if (FIND_PYTHON_INTERPRETER_EXACT AND NOT FIND_PYTHON_INTERPRETER_VERSION)
		message(FATAL_ERROR "Specified EXACT but did not specify VERSION!")
	endif()


	# Defaults
	if (NOT FIND_PYTHON_INTERPRETER_VERSION)
		set(FIND_PYTHON_INTERPRETER_VERSION "0.0.0")
	endif()
	if (NOT FIND_PYTHON_INTERPRETER_HINTS)
		set(FIND_PYTHON_INTERPRETER_HINTS "")
	endif()


	# Validate
	if (NOT FIND_PYTHON_INTERPRETER_VERSION MATCHES "^[0-9]+(\.[0-9]+(\.[0-9]+)?)?$")
		message(FATAL_ERROR "Invalid VERSION \"FIND_PYTHON_INTERPRETER_VERSION\" - must follow RegEx \"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?$\"")
	endif()




	# Define helper macro to verify found python interpreter
	set(TEST_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/find_python_interpreter_test_script.py")
	file(WRITE "${TEST_SCRIPT}" "print('It worked')")

	macro(CHECK_INTERPRETER INTERPRETER_PATH QUIET)
		# Verify that the version found is the one that is wanted
		execute_process(
			COMMAND ${INTERPRETER_PATH} "--version"
			OUTPUT_VARIABLE INTERPRETER_VERSION
			ERROR_VARIABLE INTERPRETER_VERSION # Python 2 reports the version on stderr
		)

		# Remove leading "Python " from version information
		string(REPLACE "Python " "" INTERPRETER_VERSION "${INTERPRETER_VERSION}")
		string(STRIP "${INTERPRETER_VERSION}" INTERPRETER_VERSION)

		set(INTERPRETER_OK FALSE)
		if (INTERPRETER_VERSION VERSION_LESS FIND_PYTHON_INTERPRETER_VERSION)
			set(MSG "Found Python version ${INTERPRETER_VERSION} at '${INTERPRETER_PATH}' but require at least ${FIND_PYTHON_INTERPRETER_VERSION}")
		elseif(INTERPRETER_VERSION VERSION_GREATER FIND_PYTHON_INTERPRETER_VERSION AND FIND_PYTHON_INTERPRETER_EXACT)
			set(MSG "Found Python interpreter version ${INTERPRETER_VERSION}  at '${INTERPRETER_PATH}' but require exactly ${FIND_PYTHON_INTERPRETER_VERSION}")
		else()
			set(MSG "Found Python interpreter version ${INTERPRETER_VERSION} at '${INTERPRETER_PATH}'")
			set(INTERPRETER_OK TRUE)
		endif()

		if (NOT ${QUIET})
			message(STATUS "${MSG}")
		endif()

		if (INTERPRETER_OK)
			# Check that we can run a simple script from the command line
			execute_process(
				COMMAND ${INTERPRETER_PATH} "${TEST_SCRIPT}"
				OUTPUT_QUIET
				ERROR_QUIET
				RESULT_VARIABLE EXIT_CODE
			)

			if (NOT EXIT_CODE STREQUAL "0")
				set(INTERPRETER_OK FALSE)
			endif()
		endif()

	endmacro()



	# "parse" version (first append 0.0.0 in case only a part of the version scheme was set by the user)
	string(CONCAT VERSION_HELPER "${FIND_PYTHON_INTERPRETER_VERSION}" ".0.0.0")
	string(REPLACE "." ";" VERSION_LIST "${VERSION_HELPER}")
	list(GET VERSION_LIST 0 FIND_PYTHON_INTERPRETER_VERSION_MAJOR)
	list(GET VERSION_LIST 1 FIND_PYTHON_INTERPRETER_VERSION_MINOR)
	list(GET VERSION_LIST 1 FIND_PYTHON_INTERPRETER_VERSION_PATCH)


	# Create names for the interpreter to search for
	set(INTERPRETER_NAMES "")
	if (FIND_PYTHON_INTERPRETER_VERSION_MAJOR STREQUAL "0")
		# Search for either Python 2 or 3
		list(APPEND INTERPRETER_NAMES "python3")
		list(APPEND INTERPRETER_NAMES "python")
		list(APPEND INTERPRETER_NAMES "python2")
	else()
		# Search for specified version
		list(APPEND INTERPRETER_NAMES "python${FIND_PYTHON_INTERPRETER_VERSION_MAJOR}")
		list(APPEND INTERPRETER_NAMES "python")

		if (NOT FIND_PYTHON_INTERPRETER_VERSION_MINOR EQUAL 0)
			list(PREPEND INTERPRETER_NAMES "python${FIND_PYTHON_INTERPRETER_VERSION_MAJOR}.${FIND_PYTHON_INTERPRETER_VERSION_MINOR}")

			if (NOT FIND_PYTHON_INTERPRETER_VERSION_PATCH EQUAL 0)
				list(PREPEND INTERPRETER_NAMES
					"python${FIND_PYTHON_INTERPRETER_VERSION_MAJOR}.${FIND_PYTHON_INTERPRETER_VERSION_MINOR}.${FIND_PYTHON_INTERPRETER_VERSION_PATCH}")
			endif()
		endif()
	endif()

	# Start by trying to search for a python executable via find_program
	set(PREV_IGNORE_PATHS ${CMAKE_IGNORE_PATH})
	foreach (CURRENT_NAME IN LISTS INTERPRETER_NAMES)
		while (NOT DEFINED PYTHON_INTERPRETER OR PYTHON_INTERPRETER)
			find_program(PYTHON_INTERPRETER NAMES ${CURRENT_NAME} HINTS ${FIND_PYTHON_INTERPRETER_HINTS})

			if (NOT PYTHON_INTERPRETER)
				break()
			endif()

			CHECK_INTERPRETER("${PYTHON_INTERPRETER}" TRUE)

			if (INTERPRETER_OK)
				break()
			endif()

			# Skip the just found directory in the next iteration
			get_filename_component(FOUND_DIR "${PYTHON_INTERPRETER}" DIRECTORY)
			list(APPEND CMAKE_IGNORE_PATH "${FOUND_DIR}")
		endwhile()

		if (INTERPRETER_OK)
			break()
		endif()

		unset(PYTHON_INTERPRETER)
	endforeach()


	if (NOT PYTHON_INTERPRETER)
		# Fall back to find_package
		message(VERBOSE "Can't find Python interpreter in PATH -> Falling back to find_package")
		if (FIND_PYTHON_INTERPRETER_VERSION_MAJOR EQUAL 0)
			# Search arbitrary version
			find_package(Python COMPONENTS Interpreter QUIET)
			set(PYTHON_INTERPRETER "${Python_EXECUTABLE}")
		else()
			# Search specific version (Python 2 or 3)
			find_package(Python${FIND_PYTHON_INTERPRETER_VERSION_MAJOR} COMPONENTS Interpreter QUIET)
			set(PYTHON_INTERPRETER "${Python${FIND_PYTHON_INTERPRETER_VERSION_MAJOR}_EXECUTABLE}")
		endif()
	endif()


	if (PYTHON_INTERPRETER)
		CHECK_INTERPRETER("${PYTHON_INTERPRETER}" FALSE)

		if (INTERPRETER_OK)
			set(PYTHON_INTERPRETER_VERSION "${INTERPRETER_VERSION}")
		else()
			set(PYTHON_INTERPRETER "NOTFOUND")
			set(PYTHON_INTERPRETER_VERSION "NOTFOUND")
		endif()
	else()
		set(PYTHON_INTERPRETER_VERSION "NOTFOUND")
	endif()


	# Set "return" values
	set(${FIND_PYTHON_INTERPRETER_INTERPRETER_OUT_VAR} "${PYTHON_INTERPRETER}" PARENT_SCOPE)
	if (FIND_PYTHON_INTERPRETER_VERSION_OUT_VAR)
		set(${FIND_PYTHON_INTERPRETER_VERSION_OUT_VAR} "${PYTHON_INTERPRETER_VERSION}" PARENT_SCOPE)
	endif()

	if (NOT PYTHON_INTERPRETER AND FIND_PYTHON_INTERPRETER_REQUIRED)
		message(FATAL_ERROR "Did NOT find Python interpreter")
	endif()
endfunction()

