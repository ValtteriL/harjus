#include <iostream>
#include <string>
#include "Configuration.h"
#include "Exchange.h"
#include "Trade.h"
#include "Arbmapper.h"
#include "Application.h"
#include <quickfix/SSLSocketInitiator.h>
#include <quickfix/ThreadedSSLSocketInitiator.h>
#include <quickfix/SocketInitiator.h>
#include <quickfix/SessionSettings.h>
#include <quickfix/FileStore.h>
#include <quickfix/Log.h>

void banner()
{
  std::cout << R"(
                      :=======:.
                    :============.
                  .-==+++=++======-
              .:==========++*+++==+=.
           :==-=--=---===+=====++=:
        :=**=::--=====Harjus======+=:.
      :++++=:-:=-=-==-==============+++=:
     ==+=::-:-=-=========+=====+===++===+*=:
    :=++=:::==:-=====-::::::-========+*+++++=.
    :++--:-:-:::::::..    .=+==+=::--==++++++=.
     ..                     :.  .    :=*+-+++***=:
                                       :+:.=**+*=:
                                           :***.
                                            =++:
                                            .*+:
                                             =+:
                                             :=

    )" << std::endl;
}

int main()
{
  banner();
  Configuration config;

  // FIX Engine config
  std::string fixConfig = R"(
  # default settings for sessions
  [DEFAULT]
  ConnectionType=initiator
  SenderCompID=HARJUS
  TargetCompID=SPOT
  DefaultApplVerID=FIX.4.4
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-oe.xml
  SocketConnectPort=)" + config.getBinanceFIXApiPort() +
                          R"(
  SocketConnectHost=)" + config.getBinanceFIXApiHostname() +
                          R"(

  # set TCP_NODELAY (disable Nagle's algorithm)
  # this is required for low latency
  SocketNodelay=Y

  # market data session
  [SESSION]
  SessionQualifier=MARKETDATA

  )";

  // stream to the string
  std::istringstream fixConfigStream{fixConfig};

  // get balance, available symbols & relative values
  Balance balance = getBalance(config);
  std::unordered_map<std::string, Symbol> symbolMap = getSymbols(config);
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50> relativeValueMap = getRelativeValues(config, symbolMap);

  // calculate trading paths
  std::vector<std::string> skipSymbols = config.getBlacklistedStartSymbols();
  int maxDepth = config.getMaxTradingPathLength();
  std::vector<std::vector<Trade>> tradingPaths = getTradingPaths(&symbolMap, maxDepth, skipSymbols);

  std::cout << "Hello, World!" << std::endl;

  try
  {
    FIX::SessionSettings settings{fixConfigStream};

    Application application{config};
    FIX::FileStoreFactory storeFactory{settings};
    FIX::ScreenLogFactory logFactory{settings};

    auto initiator = std::unique_ptr<FIX::Initiator>(new FIX::ThreadedSSLSocketInitiator{application, storeFactory, settings, logFactory});

    initiator->start();
    initiator->stop();

    return 0;
  }
  catch (std::exception &e)
  {
    std::cout << e.what();
    return 1;
  }

  return 0;
}
