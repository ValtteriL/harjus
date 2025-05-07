cmake_minimum_required(VERSION 3.16)

project(harjus LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd

# Boost
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()
find_package(Boost REQUIRED COMPONENTS url system thread json graph log)

# Google Test
find_package(GTest REQUIRED)

# OpenSSL
find_package(OpenSSL REQUIRED)

# Sodium
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSODIUM REQUIRED libsodium)

# cpr https://github.com/libcpr/cpr
find_package(cpr REQUIRED)

# quickfix
find_package(quickfix REQUIRED)

# Enable all warnings
add_compile_options(-Wall -Wextra -Wpedantic)

# Optimize debug builds for speed
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")

# Optimize release builds for performance
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories(include)

add_executable(harjus
  src/Main.cpp
  src/Application.cpp
  src/Configuration.cpp
  src/Exchange.cpp
  src/Ed25519.cpp
  src/Balance.cpp
  src/Trade.cpp
  src/Arbmapper.cpp
  src/Opportunity.cpp
  src/Engine.cpp
  src/Execution.cpp
  src/ReservedTrades.cpp
  src/ExecutionReport.cpp
  src/Trader.cpp
  src/PriceUpdate.cpp
)
target_link_libraries(harjus PRIVATE OpenSSL::SSL OpenSSL::Crypto Boost::url Boost::json Boost::graph Boost::log ${LIBSODIUM_LIBRARIES} cpr::cpr quickfix)

include(GNUInstallDirs)
install(TARGETS harjus
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# testing related
include(CTest)
include(GoogleTest)

add_executable(MainTest tests/MainTest.cpp)
target_link_libraries(MainTest PRIVATE
  gtest_main
  gtest
)

gtest_discover_tests(MainTest)

add_executable(ReservedTradesTest tests/ReservedTradesTest.cpp
  src/Trade.cpp
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


add_executable(OpportunityTest tests/OpportunityTest.cpp
  src/Opportunity.cpp
  src/Trade.cpp
)
target_link_libraries(OpportunityTest PRIVATE
  gtest_main
  GTest::gmock
)

gtest_discover_tests(OpportunityTest)


add_executable(EngineTest tests/EngineTest.cpp
  src/Opportunity.cpp
  src/Trade.cpp
  src/Engine.cpp
  src/ReservedTrades.cpp
  src/Balance.cpp
  src/Execution.cpp
  src/PriceUpdate.cpp
)
target_link_libraries(EngineTest PRIVATE
  gtest_main
  GTest::gmock
  Boost::log
)

gtest_discover_tests(EngineTest)


add_executable(TraderTest tests/TraderTest.cpp
  src/Trader.cpp
  src/Opportunity.cpp
  src/Trade.cpp
  src/ReservedTrades.cpp
  src/Balance.cpp
  src/Execution.cpp
  src/ExecutionReport.cpp
)
target_link_libraries(TraderTest PRIVATE
  gtest_main
  GTest::gmock
  Boost::log
)

gtest_discover_tests(TraderTest)


add_executable(ThreadSafeQueueTest tests/ThreadSafeQueueTest.cpp)
target_link_libraries(ThreadSafeQueueTest PRIVATE
  gtest_main
  GTest::gmock
  Boost::log
)

gtest_discover_tests(ThreadSafeQueueTest)