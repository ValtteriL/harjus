cmake_minimum_required(VERSION 3.16)

project(harjus-port LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Test)

add_executable(harjus-port
  main.cpp
  stdinreader.cpp
  stdinreader.h
  engine.cpp
  engine.h
  plannedexecution.h
  plannedexecution.cpp
  tradingsymbol.h
  tradingsymbol.cpp
  offer.h
  position.h
)
target_link_libraries(harjus-port Qt${QT_VERSION_MAJOR}::Core)

include(GNUInstallDirs)
install(TARGETS harjus-port
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# testing related
enable_testing()

add_executable(testsample test/testsample.cpp)
target_link_libraries(testsample PUBLIC
  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Test
)
add_test(NAME testsample COMMAND testsample)

add_executable(testengine 
  test/testengine.cpp 
  engine.cpp
  engine.h
  tradingsymbol.h
  tradingsymbol.cpp
  plannedexecution.h
  plannedexecution.cpp
)
target_link_libraries(testengine PUBLIC
  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Test
)
add_test(NAME testengine COMMAND testengine)
