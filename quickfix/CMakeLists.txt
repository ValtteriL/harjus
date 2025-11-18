cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

set (quickfix_PROJECT_NAME quickfix)

add_definitions(-DNOMINMAX)

project(${quickfix_PROJECT_NAME} VERSION 0.1 LANGUAGES CXX C)
message("-- Project name ${CMAKE_PROJECT_NAME}")

set(CMAKE_CXX_STANDARD 17)

# Optimize debug builds for build speed
set(CMAKE_CXX_FLAGS_DEBUG "-g")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

include(QuickfixPlatformSettings)
include(QuickfixPrebuildSetup)

# add option to build shared or static
option(QUICKFIX_SHARED_LIBS "Build using shared libraries" ON)

# add option to build other targets
option(QUICKFIX_TESTS "Build quickfix tests" ON)

# add libdpdk, libfstack, libmt dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDPDK REQUIRED libdpdk)
pkg_check_modules(LIBFSTACK REQUIRED libfstack)
pkg_check_modules(LIBMT REQUIRED libmt)

# Add DPDK, F-Stack, and libmt to include directories and link libraries
include_directories(${LIBDPDK_INCLUDE_DIRS} ${LIBFSTACK_INCLUDE_DIRS} ${LIBMT_INCLUDE_DIRS})
link_directories(${LIBDPDK_LIBRARY_DIRS} ${LIBFSTACK_LIBRARY_DIRS} ${LIBMT_LIBRARY_DIRS})

find_package(OpenSSL REQUIRED)
include_directories(${OPENSSL_INCLUDE_DIR})

add_subdirectory(src)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/spec/ DESTINATION share/quickfix FILES_MATCHING PATTERN "FIX*.xml")
