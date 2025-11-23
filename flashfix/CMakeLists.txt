cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

project(Flashfix LANGUAGES CXX C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd
set(CMAKE_CXX_STANDARD 17)

# add option to build other targets
option(flashfix_TESTS "Build flashfix tests" ON)

# add libdpdk, libfstack, libmt dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDPDK REQUIRED libdpdk)
pkg_check_modules(LIBFSTACK REQUIRED libfstack)
pkg_check_modules(LIBMT REQUIRED libmt)

find_package(OpenSSL REQUIRED)


add_library(${PROJECT_NAME} SHARED
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
  src/FstackMicroThreadedSSLSocketInitiator.cpp
  src/FstackMicroThreadedSSLSocketConnection.cpp
  src/FStackSSLBIO.cpp
  src/UtilitySSL.cpp
)
target_link_libraries(${PROJECT_NAME} ${OPENSSL_LIBRARIES} pthread ${LIBFSTACK_LIBRARIES} ${LIBMT_LIBRARIES} ${LIBDPDK_LIBRARIES} rte_net_bond)
target_include_directories(${PROJECT_NAME} PRIVATE ${LIBDPDK_INCLUDE_DIRS} ${LIBFSTACK_INCLUDE_DIRS} ${LIBMT_INCLUDE_DIRS})
target_link_directories(${PROJECT_NAME} PRIVATE ${LIBDPDK_LIBRARY_DIRS} ${LIBFSTACK_LIBRARY_DIRS} ${LIBMT_LIBRARY_DIRS})

target_include_directories(${PROJECT_NAME} PRIVATE ${OPENSSL_INCLUDE_DIR})

set_target_properties(${PROJECT_NAME} PROPERTIES VERSION 1.0.0 SOVERSION 1)

target_include_directories(${PROJECT_NAME}
  INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  INTERFACE $<INSTALL_INTERFACE:include>
  PRIVATE include include/double-conversion
)

include(GNUInstallDirs)

# Install library
install(TARGETS ${PROJECT_NAME}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  
)

# install headers
install(DIRECTORY include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install FIX specification files to /share
install(DIRECTORY spec 
  DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}
  FILES_MATCHING PATTERN "FIX*.xml"
)

# Generate and install pkg-config file
configure_file(flashfix.pc.in flashfix.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/flashfix.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

# TESTS
if (flashfix_TESTS)
    add_subdirectory(test)
endif()
