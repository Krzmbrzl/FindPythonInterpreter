cmake_minimum_required(VERSION 3.5)

project("Test-FindPythonInterpreter")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")

include(FindPythonInterpreter)

find_python_interpreter(
	REQUIRED
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
	VERSION_OUT_VAR PYTHON_VERSION
)

message(STATUS "Got Python ${PYTHON_VERSION} at ${PYTHON_INTERPRETER}")
