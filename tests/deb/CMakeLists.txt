################################################################################
# DO NOT run as part of the tests
# This is meant as a "packaging test" to be used with the Dockerfiles in this folder

# c++17: needed for string_view
# c++20: why not?
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

cmake_minimum_required(VERSION 3.22)

################################################################################

find_library(ABC_LIBRARY abc REQUIRED)
find_path(ABC_INCLUDE_DIR base/main/main.h REQUIRED
        # SHOULD be installed into "/usr/include/abc/base/main/main.h"
        # so remove "abc" part
        PATH_SUFFIXES abc
)

################################################################################

add_executable(demo
    # cf COPY in tests/deb/test_deb_lib.dockerfile
    demo.c
)

target_link_libraries(demo
    PRIVATE
    # IMPORTANT: Yosys passes are "auto registered" which means that they are NOT
    # directly used. Which causes them to be optmized out when static linking
    # eg "ERROR: No such command: techmap"
    # We MUST use "whole-archive" when using STATIC to make it work.
    # -Wl,--whole-archive
    ${ABC_LIBRARY}
    # -Wl,--no-whole-archive
)

target_include_directories(demo
    PRIVATE
    ${ABC_INCLUDE_DIR}
)
