cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

set (quickfix_PROJECT_NAME quickfix)

project(${quickfix_PROJECT_NAME} VERSION 0.1 LANGUAGES CXX C)
message("-- Project name ${CMAKE_PROJECT_NAME}")

set(CMAKE_CXX_STANDARD 17)

# Optimize debug builds for build speed
set(CMAKE_CXX_FLAGS_DEBUG "-g")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

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

############################## add_subdirectory(src)
set(quickfix_SOURCES
  src/DataDictionary.cpp
  src/DataDictionaryProvider.cpp
  src/Dictionary.cpp
  src/FieldConvertors.cpp
  src/FieldMap.cpp
  src/FieldTypes.cpp
  src/FileLog.cpp
  src/FileStore.cpp
  src/Group.cpp
  src/HostDetailsProvider.cpp
  src/Initiator.cpp
  src/Log.cpp
  src/Message.cpp
  src/MessageSorters.cpp
  src/MessageStore.cpp
  src/NullStore.cpp
  src/Parser.cpp
  src/pugixml.cpp
  src/PUGIXML_DOMDocument.cpp
  src/Session.cpp
  src/SessionFactory.cpp
  src/SessionSettings.cpp
  src/Settings.cpp
  src/stdafx.cpp
  src/TimeRange.cpp
  src/Utility.cpp
  src/SocketMonitor_UNIX.cpp
  src/FstackMicroThreadedSSLSocketInitiator.cpp
  src/FstackMicroThreadedSSLSocketConnection.cpp
  src/FStackSSLBIO.cpp
  src/UtilitySSL.cpp
)


if (QUICKFIX_SHARED_LIBS)
	add_library(${PROJECT_NAME} SHARED  ${quickfix_SOURCES})
else()
	add_library(${PROJECT_NAME} STATIC  ${quickfix_SOURCES})
endif()
target_link_libraries(${PROJECT_NAME} ${OPENSSL_LIBRARIES} pthread ${LIBFSTACK_LIBRARIES} ${LIBMT_LIBRARIES} ${LIBDPDK_LIBRARIES} rte_net_bond)

set_target_properties(${PROJECT_NAME} PROPERTIES VERSION 1.0.0 SOVERSION 1)
set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER include/quickfix/quickfix.h)

target_include_directories(${PROJECT_NAME}
  INTERFACE $<INSTALL_INTERFACE:include>
  PRIVATE include include/double-conversion
)

include(GNUInstallDirs)

# Install library and headers to /lib and /include
install(TARGETS ${PROJECT_NAME}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install FIX specification files to /share
install(DIRECTORY spec 
  DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}
  FILES_MATCHING PATTERN "FIX*.xml"
  )
