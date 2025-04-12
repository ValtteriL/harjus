#include <iostream>
#include <string>
#include "Configuration.h"
#include "Exchange.h"
#include "Trade.h"
#include "Arbmapper.h"

void banner() {
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

    // get balance and available symbols
    Balance balance = getBalance(config);
    std::unordered_map<std::string, Symbol> symbolMap = getSymbols(config);

    // calculate trading paths
    std::vector<std::string> skipSymbols = config.getBlacklistedStartSymbols();
    int maxDepth = config.getMaxTradingPathLength();
    std::vector<std::vector<Trade>> tradingPaths = getTradingPaths(&symbolMap, maxDepth, skipSymbols);

    std::cout << "Hello, World!" << std::endl;
    return 0;
}
