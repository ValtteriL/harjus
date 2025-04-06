cmake_minimum_required(VERSION 3.16)

project(harjus-port LANGUAGES CXX)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Test)

# Boost
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()
find_package(Boost REQUIRED COMPONENTS url system thread)

# Google Test
find_package(GTest REQUIRED)

# OpenSSL
find_package(OpenSSL REQUIRED)

# cpp-netlib
find_package(cppnetlib REQUIRED)

# Enable all warnings
add_compile_options(-Wall -Wextra -Wpedantic)

# Optimize debug builds for speed
set(CMAKE_CXX_FLAGS_DEBUG "-O3 -g")

# Optimize release builds for performance
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories(include)

add_executable(harjus-port
  src/Main.cpp
  src/Engine.cpp
  src/PlannedExecution.cpp
  src/TradingSymbol.cpp
)
target_link_libraries(harjus-port PRIVATE Qt${QT_VERSION_MAJOR}::Core OpenSSL::SSL OpenSSL::Crypto Boost::urls)

include(GNUInstallDirs)
install(TARGETS harjus-port
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# testing related
include(CTest)
include(GoogleTest)

add_executable(MainTest tests/MainTest.cpp)
target_link_libraries(MainTest PRIVATE
  Qt${QT_VERSION_MAJOR}::Core
  gtest_main
)

gtest_discover_tests(MainTest)

add_executable(EngineTest tests/EngineTest.cpp
  src/PlannedExecution.cpp
  src/TradingSymbol.cpp
  src/Engine.cpp
)
target_link_libraries(EngineTest PRIVATE
  Qt${QT_VERSION_MAJOR}::Core
  gtest_main
)

gtest_discover_tests(EngineTest)

add_executable(PlannedExecutionTest tests/PlannedExecutionTest.cpp
  src/PlannedExecution.cpp
  src/TradingSymbol.cpp
  src/Engine.cpp
)
target_link_libraries(PlannedExecutionTest PRIVATE
  Qt${QT_VERSION_MAJOR}::Core
  gtest_main
)

gtest_discover_tests(PlannedExecutionTest)


add_executable(ReservedTradesTest tests/ReservedTradesTest.cpp
  src/ReservedTrades.cpp
  src/TradingSymbol.cpp
)
target_link_libraries(ReservedTradesTest PRIVATE
  Qt${QT_VERSION_MAJOR}::Core
  gtest_main
  GTest::gmock
)

gtest_discover_tests(ReservedTradesTest)

add_executable(BalanceTest tests/BalanceTest.cpp
  src/Balance.cpp
)
target_link_libraries(BalanceTest PRIVATE
  gtest_main
  GTest::gmock
)

gtest_discover_tests(ReservedTradesTest)
