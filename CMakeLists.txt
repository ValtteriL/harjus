cmake_minimum_required(VERSION 3.31)

project(harjus LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
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

# quickfix
find_package(quickfix REQUIRED)

# add ccache for faster builds
if(DEFINED ENV{USE_CCACHE})
  set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

add_subdirectory(src)

# testing related

if(HARJUS_TESTS)
  add_subdirectory(tests)
endif()

