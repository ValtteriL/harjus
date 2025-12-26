cmake_minimum_required(VERSION 3.31)

project(harjus LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS  OFF)

# Add sanitizers + other helpful flags in debug builds
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -Wall -Wextra -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer")
set(CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_LINKER_FLAGS_DEBUG} -fsanitize=address -fsanitize=undefined")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd

option(HARJUS_TESTS "Build Harjus tests" ON)

# Boost
find_package(Boost REQUIRED COMPONENTS url system thread json graph log)

# Google Test
find_package(GTest REQUIRED)

# OpenSSL
find_package(OpenSSL REQUIRED)

# Sodium
find_package(LibSodium REQUIRED)

# cpr https://github.com/libcpr/cpr
find_package(cpr REQUIRED)

# GMP
find_package(GMP REQUIRED)

# fstack
find_package(fstack REQUIRED)

# flashfix
add_subdirectory(flashfix)

# add ccache for faster builds
if(DEFINED ENV{USE_CCACHE})
  set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

add_subdirectory(src)

# testing related

if(HARJUS_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

