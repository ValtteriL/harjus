# internal library
add_library(harjus_objs OBJECT
  Application.cpp
  Configuration.cpp
  Globals.cpp
  Exchange.cpp
  Ed25519.cpp
  Balance.cpp
  Trade.cpp
  Arbmapper.cpp
  Opportunity.cpp
  Execution.cpp
  ReservedTrades.cpp
  ExecutionReport.cpp
  Worker.cpp
  PriceUpdate.cpp
  StaticTrade.cpp
  FixConfig.cpp
  PreciseNumber.cpp
)

target_include_directories(harjus_objs
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(harjus_objs 
  PUBLIC
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

target_compile_options(harjus_objs PRIVATE
  -Wall -Wextra -Wpedantic -Werror
)

# harjus executable
add_executable(harjus
  Main.cpp
)
target_include_directories(harjus
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(harjus
  PRIVATE
    harjus_objs
)

target_compile_options(harjus PRIVATE
  -Wall -Wextra -Wpedantic -Werror
)

include(GNUInstallDirs)
install(TARGETS harjus
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# for quickfix
add_compile_definitions(HAVE_SSL)