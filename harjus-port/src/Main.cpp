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
  ReconnectInterval=60
  SenderCompID=TW

  # session definition
  [SESSION]
  # inherit ConnectionType, ReconnectInterval and SenderCompID from default
  BeginString=FIX.4.1
  TargetCompID=ARCA
  StartTime=12:30:00
  EndTime=23:30:00
  HeartBtInt=20
  SocketConnectPort=9823
  SocketConnectHost=123.123.123.123
  DataDictionary=somewhere/FIX41.xml

  [SESSION]
  BeginString=FIX.4.0
  TargetCompID=ISLD
  StartTime=12:00:00
  EndTime=23:00:00
  HeartBtInt=30
  SocketConnectPort=8323
  SocketConnectHost=23.23.23.23
  DataDictionary=somewhere/FIX40.xml

  [SESSION]
  BeginString=FIX.4.2
  TargetCompID=INCA
  StartTime=12:30:00
  EndTime=21:30:00
  # overide default setting for RecconnectInterval
  ReconnectInterval=30
  HeartBtInt=30
  SocketConnectPort=6523
  SocketConnectHost=3.3.3.3
  # (optional) alternate connection ports and hosts to cycle through on failover
  SocketConnectPort1=8392
  SocketConnectHost1=8.8.8.8
  SocketConnectPort2=2932
  SocketConnectHost2=12.12.12.12
  DataDictionary=somewhere/FIX42.xml
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
