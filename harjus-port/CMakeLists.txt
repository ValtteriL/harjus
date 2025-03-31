cmake_minimum_required(VERSION 3.16)

project(harjus-port LANGUAGES CXX)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Test)

# Enable all warnings
add_compile_options(-Wall -Wextra -Wpedantic)

# Optimize debug builds for speed
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")

# Optimize release builds for performance
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories(include)

add_executable(harjus-port
  src/Main.cpp
  src/Engine.cpp
  src/PlannedExecution.cpp
  src/TradingSymbol.cpp
)
target_link_libraries(harjus-port Qt${QT_VERSION_MAJOR}::Core)

include(GNUInstallDirs)
install(TARGETS harjus-port
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# testing related
enable_testing()

# gather all test files
file(GLOB TEST_FILES
  tests/*.cpp
)

add_executable(all-tests ${TEST_FILES}
  src/PlannedExecution.cpp
  src/TradingSymbol.cpp
  src/Engine.cpp
)
target_link_libraries(all-tests PUBLIC
  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Test
)
add_test(NAME all-tests COMMAND all-tests)
