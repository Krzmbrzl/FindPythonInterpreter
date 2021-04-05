# FindPythonInterpreter

## Motivation and purpose

I used to search for a Python interpreter like this
```bash
find_package(Python3 COMPONENTS Interpreter REQUIRED)
```
but the `find_package` approach tended to yield weird results. Either it found very exotic (unexpected) Python binaries (probably due to it always
search for the newest version available) or it found a binary that it claimed was not executable.

While in the second case the entire procedure simply was unusable, the first scenario could cause weird situations if there was a requirement for some
Python module to be installed. The user would install the module from the command-line but due to `find_package` finding a different executable than
the one the user used on the command line, the found Python interpreter did not know anything about that module and thus the executed script would
fail.

It just seems that `find_package` is an overkill for just finding a Python interpreter and therefore I wrote this script that tries to find a Python
interpreter in the standard locations (presumably (also) the ones contained in `PATH`) and only falls back to `find_package` if that fails.

## How to use

### Adding to your project

In order to add this script to your project, simply copy the `FindPythonInterpreter.cmake` file into your project. Typically such scripts are placed
in a subdirectory called `cmake` in your project's root, but this is not required.

Then you have to extend [CMAKE_MODULE_PATH](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) in your `CMakeLists.txt` in order for
it to contain the directory to which you copied `FindPythonInterpreter.cmake`. If you used the standard convention, you can use
```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
```

Finally you have to include the script into your `CMakeLists.txt`:
```cmake
include(FindPythonInterpreter)
```

### Usage

The script defines a single function called `find_python_interpreter`. A minimal example of how to use this function would be
```cmake
find_python_interpreter(
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
)
```
This will search for any version of a Python interpreter (Python 2 or Python 3 while preferring Python 3) and if it succeeds, it'll store the path to
the interpreter's executable in `PYTHON_INTERPRETER` (you can freely choose this name). If no interpreter is found, the respective variable will be
set to `NOTFOUND`.

If you want to make sure that only a Python 3 interpreter will be found, you can use the `VERSION` parameter:
```cmake
find_python_interpreter(
	VERSION 3
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
)
```

You can also specify the desired version in more detail (e.g. `3.2` or even `3.2.5`). By default the passed version will be considered a _minimal_
version that the found interpreter has to fulfill. If you want to find an interpreter with _exactly_ the version as entered, you have to supply the
`EXACT` flag:
```cmake
find_python_interpreter(
	VERSION 3.2.1
	EXACT
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
)
```
Note however that the scipt is not really optimized for finding exact versions, so the usage of `EXACT` will most likely lead to the search failing.

If you want that a failure of finding a suitable interpreter is considered as an error, you can pass the `REQUIRED` option:
```cmake
find_python_interpreter(
	VERSION 3
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
	REQUIRED
)
```

If you are also interested in the exact version of the interpreter found, use `VERSION_OUT_VAR` like this:
```cmake
find_python_interpreter(
	INTERPRETER_OUT_VAR PYTHON_INTERPRETER
	VERSION_OUT_VAR PYTHON_VERSION
)
```
On successful execution, this will store the interpreter's version in `PYTHON_VERSION` (again: The name can be freely chosen). If no interpreter is
found, then this variable will also be set to `NOTFOUND`.

### Reference

```cmake
find_python_interpreter(
	INTERPRETER_OUT_VAR var
	[VERSION_OUT_VAR var]
	[VERSION version]
	[REQUIRED]
	[EXACT]
	[HINTS path1 [path2 ...]]
)
```

| **Option** | **Description** |
| ---------- | --------------- |
| `INTERPRETER_OUT_VAR`| Name of the variable to store the path to the found interpreter in |
| `VERSION_OUT_VAR`| Name of the variable to store the version of the found interpreter in |
| `VERSION`| (Minimum) version of the interpreter to search for |
| `REQUIRED`| Bail out (error) if no suitable interpreter is found |
| `EXACT`| Search for the exact passed version instead of treating it as the minimum version |
| `HINTS`| A list of paths to also look in when searching for the interpreter |
