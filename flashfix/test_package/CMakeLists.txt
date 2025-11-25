cmake_minimum_required(VERSION 3.15)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(PackageTest CXX)

find_package(flashfix CONFIG REQUIRED)

# Add system dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDPDK REQUIRED libdpdk IMPORTED_TARGET)
pkg_check_modules(LIBFSTACK REQUIRED libfstack IMPORTED_TARGET)
pkg_check_modules(LIBMT REQUIRED libmt IMPORTED_TARGET)

add_executable(example src/example.cpp)
target_link_libraries(example flashfix::flashfix PkgConfig::LIBDPDK PkgConfig::LIBFSTACK PkgConfig::LIBMT)
