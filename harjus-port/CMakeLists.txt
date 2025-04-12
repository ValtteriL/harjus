cmake_minimum_required(VERSION 3.16)

project(harjus-port LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd

# Boost
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()
find_package(Boost REQUIRED COMPONENTS url system thread json graph)

# Google Test
find_package(GTest REQUIRED)

# OpenSSL
find_package(OpenSSL REQUIRED)

# Sodium
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSODIUM REQUIRED libsodium)

# cpr https://github.com/libcpr/cpr
find_package(cpr REQUIRED)

# Enable all warnings
add_compile_options(-Wall -Wextra -Wpedantic)

# Optimize debug builds for speed
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")

# Optimize release builds for performance
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories(include)

add_executable(harjus-port
  src/Main.cpp
  src/Configuration.cpp
  src/Exchange.cpp
  src/Ed25519.cpp
  src/Balance.cpp
  src/Trade.cpp
  src/Arbmapper.cpp
)
target_link_libraries(harjus-port PRIVATE OpenSSL::SSL OpenSSL::Crypto Boost::url Boost::json Boost::graph ${LIBSODIUM_LIBRARIES} cpr::cpr)

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
  gtest_main
)

gtest_discover_tests(MainTest)

add_executable(ReservedTradesTest tests/ReservedTradesTest.cpp
  src/ReservedTrades.cpp
)
target_link_libraries(ReservedTradesTest PRIVATE
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

add_executable(Ed25519Test tests/Ed25519Test.cpp
  src/Ed25519.cpp
)
target_link_libraries(Ed25519Test PRIVATE
  gtest_main
  GTest::gmock
  ${LIBSODIUM_LIBRARIES}
)

gtest_discover_tests(Ed25519Test)


add_executable(ExchangeTest tests/ExchangeTest.cpp
  src/Exchange.cpp
  src/Ed25519.cpp
  src/Balance.cpp
)
target_link_libraries(ExchangeTest PRIVATE
  gtest_main
  GTest::gmock
  Boost::url
  ${LIBSODIUM_LIBRARIES}
  cpr::cpr
  Boost::json
)

gtest_discover_tests(ExchangeTest)


add_executable(ArbmapperTest tests/ArbmapperTest.cpp
  src/Arbmapper.cpp
  src/Trade.cpp
)
target_link_libraries(ArbmapperTest PRIVATE
  gtest_main
  GTest::gmock
  Boost::graph
)

gtest_discover_tests(ArbmapperTest)