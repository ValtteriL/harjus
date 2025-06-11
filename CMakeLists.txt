cmake_minimum_required(VERSION 3.16)

project(harjus LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd

option(HARJUS_TESTS "Build Harjus tests" ON)

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

# GMP
pkg_check_modules(GMP REQUIRED gmp)

# quickfix
find_package(quickfix REQUIRED)

# Enable all warnings
add_compile_options(-Wall -Wextra -Wpedantic)

# Optimize debug builds for speed
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")

# Optimize release builds for performance
set(CMAKE_CXX_FLAGS_RELEASE "-O3")


# add ccache for faster builds
if(DEFINED ENV{USE_CCACHE})
  set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

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
  src/StaticTrade.cpp
  src/FixConfig.cpp
  src/PreciseNumber.cpp
)
target_link_libraries(harjus PRIVATE OpenSSL::SSL OpenSSL::Crypto Boost::url Boost::json Boost::graph Boost::log ${LIBSODIUM_LIBRARIES} ${GMP_LIBRARIES} cpr::cpr quickfix)

include(GNUInstallDirs)
install(TARGETS harjus
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# testing related

if(HARJUS_TESTS)

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
    src/StaticTrade.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(ReservedTradesTest PRIVATE
    gtest_main
    GTest::gmock
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(ReservedTradesTest)

  add_executable(BalanceTest tests/BalanceTest.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(BalanceTest PRIVATE
    gtest_main
    GTest::gmock
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(ReservedTradesTest)

  add_executable(Ed25519Test tests/Ed25519Test.cpp
    src/Ed25519.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(Ed25519Test PRIVATE
    gtest_main
    GTest::gmock
    ${LIBSODIUM_LIBRARIES}
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(Ed25519Test)


  add_executable(ExchangeTest tests/ExchangeTest.cpp
    src/Exchange.cpp
    src/Ed25519.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(ExchangeTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::url
    ${LIBSODIUM_LIBRARIES}
    ${GMP_LIBRARIES}
    cpr::cpr
    Boost::json
  )

  gtest_discover_tests(ExchangeTest)


  add_executable(ArbmapperTest tests/ArbmapperTest.cpp
    src/Arbmapper.cpp
    src/Trade.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(ArbmapperTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::graph
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(ArbmapperTest)


  add_executable(OpportunityTest tests/OpportunityTest.cpp
    src/Opportunity.cpp
    src/Trade.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(OpportunityTest PRIVATE
    gtest_main
    GTest::gmock
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(OpportunityTest)


  add_executable(EngineTest tests/EngineTest.cpp
    src/Opportunity.cpp
    src/Trade.cpp
    src/Engine.cpp
    src/ReservedTrades.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
    src/Execution.cpp
    src/PriceUpdate.cpp
    src/StaticTrade.cpp
  )
  target_link_libraries(EngineTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::log
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(EngineTest)


  add_executable(TraderTest tests/TraderTest.cpp
    src/Trader.cpp
    src/Opportunity.cpp
    src/Trade.cpp
    src/ReservedTrades.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
    src/Execution.cpp
    src/ExecutionReport.cpp
    src/StaticTrade.cpp
  )
  target_link_libraries(TraderTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::log
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(TraderTest)


  add_executable(ThreadSafeQueueTest tests/ThreadSafeQueueTest.cpp)
  target_link_libraries(ThreadSafeQueueTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::log
  )

  gtest_discover_tests(ThreadSafeQueueTest)


  add_executable(PreciseNumberTest tests/PreciseNumberTest.cpp
    src/PreciseNumber.cpp
  )
  target_link_libraries(PreciseNumberTest PRIVATE
    gtest_main
    GTest::gmock
    Boost::log
    ${GMP_LIBRARIES}
  )

  gtest_discover_tests(PreciseNumberTest)

endif()

# optimize build time with precompiled headers

# Define Boost macros globally to avoid PCH issues
add_compile_definitions(BOOST_CONTAINER_NO_LIB)
add_compile_definitions(BOOST_CONTAINER_DYN_LINK)
add_compile_definitions(BOOST_LOG_NO_LIB)
add_compile_definitions(BOOST_LOG_DYN_LINK)
add_compile_definitions(BOOST_THREAD_DYN_LINK)
add_compile_definitions(BOOST_THREAD_NO_LIB)
add_compile_definitions(BOOST_CHRONO_NO_LIB)
add_compile_definitions(BOOST_CHRONO_DYN_LINK)
add_compile_definitions(BOOST_URL_NO_LIB)
add_compile_definitions(BOOST_URL_DYN_LINK)
add_compile_definitions(HAVE_STD_UNIQUE_PTR)
add_compile_definitions(BOOST_ATOMIC_NO_LIB)
add_compile_definitions(BOOST_ATOMIC_DYN_LINK)
add_compile_definitions(HAVE_STD_SHARED_PTR)
add_compile_definitions(BOOST_GRAPH_NO_LIB)
add_compile_definitions(BOOST_GRAPH_DYN_LINK)
add_compile_definitions(BOOST_JSON_NO_LIB)
add_compile_definitions(BOOST_JSON_DYN_LINK)
add_compile_definitions(BOOST_REGEX_NO_LIB)
add_compile_definitions(BOOST_REGEX_DYN_LINK)
add_compile_definitions(BOOST_FILESYSTEM_NO_LIB)
add_compile_definitions(BOOST_FILESYSTEM_DYN_LINK)
# and same for quickfix
add_compile_definitions(HAVE_SSL)


target_precompile_headers(harjus PRIVATE

  # Standard Library
  <iostream>
  <string>
  <cstring>
  <unordered_map>
  <unordered_set>
  <vector>
  <thread>
  <mutex>
  <shared_mutex>
  <stop_token>
  <queue>
  <fstream>
  <ostream>
  <utility>
  <memory>
  <semaphore>
  <filesystem>
  <thread>
  <cmath>
  <random>
  <condition_variable>
  <chrono>
  <algorithm>
  <functional>
  <iomanip>
  <stdexcept>

  # Boost
  <boost/log/core.hpp>
  <boost/log/expressions.hpp>
  <boost/log/trivial.hpp>
  <boost/graph/adjacency_list.hpp>
  <boost/graph/tiernan_all_cycles.hpp>
  <boost/json.hpp>
  <boost/multiprecision/gmp.hpp>
  <boost/multiprecision/cpp_dec_float.hpp>
  <boost/lockfree/spsc_queue.hpp>


  # Quickfix Engine
  <quickfix/Application.h>
  <quickfix/MessageCracker.h>
  <quickfix/Mutex.h>
  <quickfix/SessionID.h>
  <quickfix/Values.h>
  <quickfix/fix44/ExecutionReport.h>
  <quickfix/fix44/MarketDataIncrementalRefresh.h>
  <quickfix/fix44/MarketDataRequest.h>
  <quickfix/fix44/MarketDataSnapshotFullRefresh.h>
  <quickfix/fix44/NewOrderSingle.h>
  <quickfix/fix44/OrderCancelReject.h>
  <quickfix/fix44/OrderCancelReplaceRequest.h>
  <quickfix/fix44/OrderCancelRequest.h>
  <quickfix/Field.h>
  <quickfix/FixFields.h>
  <quickfix/FixValues.h>
  <quickfix/Session.h>
  <quickfix/fix44/MarketDataRequestReject.h>
  <quickfix/fix44/Reject.h>
  <quickfix/FileStore.h>
  <quickfix/Log.h>
  <quickfix/SSLSocketInitiator.h>
  <quickfix/SessionSettings.h>
  <quickfix/SocketInitiator.h>
  <quickfix/ThreadedSSLSocketInitiator.h>
)

if(HARJUS_TESTS)
  target_precompile_headers(MainTest REUSE_FROM harjus)
  target_precompile_headers(ReservedTradesTest REUSE_FROM harjus)
  target_precompile_headers(BalanceTest REUSE_FROM harjus)
  target_precompile_headers(Ed25519Test REUSE_FROM harjus)
  target_precompile_headers(ExchangeTest REUSE_FROM harjus)
  target_precompile_headers(ArbmapperTest REUSE_FROM harjus)
  target_precompile_headers(OpportunityTest REUSE_FROM harjus)
  target_precompile_headers(EngineTest REUSE_FROM harjus)
  target_precompile_headers(TraderTest REUSE_FROM harjus)
  target_precompile_headers(ThreadSafeQueueTest REUSE_FROM harjus)
endif()
