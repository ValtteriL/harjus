#include <iostream>
#include <string>
#include "Configuration.h"

int main()
{
    Configuration config;
    std::cout << "Binance REST API URI: " << config.getBinanceRESTApiUri() << std::endl;
    std::cout << "Binance FIX API Hostname: " << config.getBinanceFIXApiHostname() << std::endl;
    std::cout << "Binance FIX API Port: " << config.getBinanceFIXApiPort() << std::endl;

    std::cout << "Hello, World!" << std::endl;
    return 0;
}
