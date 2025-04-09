#include <iostream>
#include <string>
#include "Configuration.h"
#include "Exchange.h"

int main()
{
    Configuration config;
    std::cout << "Binance REST API URI: " << config.getBinanceRESTApiUri() << std::endl;
    std::cout << "Binance FIX API Hostname: " << config.getBinanceFIXApiHostname() << std::endl;
    std::cout << "Binance FIX API Port: " << config.getBinanceFIXApiPort() << std::endl;

    // get balance and available symbols
    Balance balance = getBalance(config);
    std::unordered_map<std::string, Symbol> symbolMap = getSymbols(config);

    // TODO: calculate trading paths

    std::cout << "Hello, World!" << std::endl;
    return 0;
}
