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
  std::cout << "Binance REST API URI: " << config.getBinanceRESTApiUri() << std::endl;
  std::cout << "Binance FIX API Hostname: " << config.getBinanceFIXApiHostname() << std::endl;
  std::cout << "Binance FIX API Port: " << config.getBinanceFIXApiPort() << std::endl;

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
    FIX::SessionSettings settings{"thisdoesnotexist.cfg"};

    Application application;
    FIX::FileStoreFactory storeFactory{settings};
    FIX::ScreenLogFactory logFactory{settings};

    auto initiator = std::unique_ptr<FIX::Initiator>(new FIX::ThreadedSSLSocketInitiator{application, storeFactory, settings, logFactory});

    initiator->start();
    application.run();
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
