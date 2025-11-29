include(CTest)
include(GoogleTest)

enable_testing()

add_executable(MainTest MainTest.cpp)
target_include_directories(MainTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(MainTest PRIVATE
  GTest::gtest_main
  GTest::gtest
)

gtest_discover_tests(MainTest)

add_executable(ReservedTradesTest ReservedTradesTest.cpp)
target_include_directories(ReservedTradesTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(ReservedTradesTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(ReservedTradesTest)

add_executable(BalanceTest BalanceTest.cpp)
target_include_directories(BalanceTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(BalanceTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  gmp::gmp
  boost::boost
)

gtest_discover_tests(ReservedTradesTest)

add_executable(Ed25519Test Ed25519Test.cpp)
target_include_directories(Ed25519Test 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(Ed25519Test PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  libsodium::libsodium
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(Ed25519Test)


add_executable(ExchangeTest ExchangeTest.cpp)
target_include_directories(ExchangeTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(ExchangeTest PRIVATE
  harjus_objs
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


add_executable(ArbmapperTest ArbmapperTest.cpp)
target_include_directories(ArbmapperTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(ArbmapperTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  Boost::graph
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(ArbmapperTest)


add_executable(OpportunityTest OpportunityTest.cpp)
target_include_directories(OpportunityTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(OpportunityTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(OpportunityTest)


add_executable(WorkerTest WorkerTest.cpp)
target_include_directories(WorkerTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(WorkerTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  Boost::log
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(WorkerTest)

add_executable(PreciseNumberTest PreciseNumberTest.cpp)
target_include_directories(PreciseNumberTest 
PRIVATE
	${CMAKE_SOURCE_DIR}/include
)
target_link_libraries(PreciseNumberTest PRIVATE
  harjus_objs
  GTest::gtest_main
  GTest::gmock
  Boost::log
  gmp::gmp
  Boost::boost
)

gtest_discover_tests(PreciseNumberTest)
