cmake_minimum_required(VERSION 3.31)

project(harjus LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # for clangd

option(HARJUS_TESTS "Build Harjus tests" ON)

# Boost
find_package(Boost REQUIRED COMPONENTS url system thread json graph log)

# Google Test
find_package(GTest REQUIRED)

# OpenSSL
find_package(OpenSSL REQUIRED)

# Sodium
find_package(LibSodium REQUIRED)

# cpr https://github.com/libcpr/cpr
find_package(cpr REQUIRED)

# GMP
find_package(GMP REQUIRED)

# quickfix
find_package(quickfix REQUIRED)

# add ccache for faster builds
if(DEFINED ENV{USE_CCACHE})
  set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

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
  src/Execution.cpp
  src/ReservedTrades.cpp
  src/ExecutionReport.cpp
  src/Worker.cpp
  src/PriceUpdate.cpp
  src/StaticTrade.cpp
  src/FixConfig.cpp
  src/PreciseNumber.cpp
)
target_include_directories(harjus 
  PRIVATE
  	include
)
target_link_libraries(harjus 
  PRIVATE
    OpenSSL::SSL
    OpenSSL::Crypto
    Boost::boost
    Boost::url
    Boost::json
    Boost::graph
    Boost::log
    libsodium::libsodium
    gmp::gmp
    cpr::cpr
    quickfix
)

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
  target_include_directories(MainTest 
  PRIVATE
  	include
  )
  target_link_libraries(MainTest PRIVATE
    GTest::gtest_main
    GTest::gtest
  )

  gtest_discover_tests(MainTest)

  add_executable(ReservedTradesTest tests/ReservedTradesTest.cpp
    src/Trade.cpp
    src/ReservedTrades.cpp
    src/StaticTrade.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(ReservedTradesTest 
  PRIVATE
  	include
  )
  target_link_libraries(ReservedTradesTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(ReservedTradesTest)

  add_executable(BalanceTest tests/BalanceTest.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(BalanceTest 
  PRIVATE
  	include
  )
  target_link_libraries(BalanceTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    gmp::gmp
    boost::boost
  )

  gtest_discover_tests(ReservedTradesTest)

  add_executable(Ed25519Test tests/Ed25519Test.cpp
    src/Ed25519.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(Ed25519Test 
  PRIVATE
  	include
  )
  target_link_libraries(Ed25519Test PRIVATE
    GTest::gtest_main
    GTest::gmock
    libsodium::libsodium
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(Ed25519Test)


  add_executable(ExchangeTest tests/ExchangeTest.cpp
    src/Exchange.cpp
    src/Ed25519.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(ExchangeTest 
  PRIVATE
  	include
  )
  target_link_libraries(ExchangeTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    Boost::url
    libsodium::libsodium
    gmp::gmp
    cpr::cpr
    Boost::json
    Boost::boost
  )

  gtest_discover_tests(ExchangeTest)


  add_executable(ArbmapperTest tests/ArbmapperTest.cpp
    src/Arbmapper.cpp
    src/Trade.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(ArbmapperTest 
  PRIVATE
  	include
  )
  target_link_libraries(ArbmapperTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    Boost::graph
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(ArbmapperTest)


  add_executable(OpportunityTest tests/OpportunityTest.cpp
    src/Opportunity.cpp
    src/Trade.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(OpportunityTest 
  PRIVATE
  	include
  )
  target_link_libraries(OpportunityTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(OpportunityTest)


  add_executable(WorkerTest tests/WorkerTest.cpp
    src/Opportunity.cpp
    src/Trade.cpp
    src/ReservedTrades.cpp
    src/Balance.cpp
    src/PreciseNumber.cpp
    src/Execution.cpp
    src/ExecutionReport.cpp
    src/PriceUpdate.cpp
    src/StaticTrade.cpp
    src/Worker.cpp
  )
  target_include_directories(WorkerTest 
  PRIVATE
  	include
)
  target_link_libraries(WorkerTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    Boost::log
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(WorkerTest)

  add_executable(PreciseNumberTest tests/PreciseNumberTest.cpp
    src/PreciseNumber.cpp
  )
  target_include_directories(PreciseNumberTest 
  PRIVATE
  	include
  )
  target_link_libraries(PreciseNumberTest PRIVATE
    GTest::gtest_main
    GTest::gmock
    Boost::log
    gmp::gmp
    Boost::boost
  )

  gtest_discover_tests(PreciseNumberTest)

endif()

add_compile_definitions(HAVE_SSL)

