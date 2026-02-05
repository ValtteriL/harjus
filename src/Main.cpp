#include "Arbmapper.h"
#include "Configuration.h"
#include "Exchange.h"
#include "ExecutionReport.h"
#include "FixConfig.h"
#include "Globals.h"
#include "HarjusApplication.h"
#include "PriceUpdate.h"
#include "Trade.h"
#include "Worker.h"
#include <FileStore.h>
#include <FstackMicroThreadedSSLSocketInitiator.h>
#include <Log.h>
#include <MessageStore.h>
#include <SessionSettings.h>
#include <UtilitySSL.h>
#include <boost/lockfree/spsc_queue.hpp>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>
#include <unordered_set>
#include <vector>

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

void initLogging(int logLevel)
{
    boost::log::core::get()->set_filter(boost::log::trivial::severity >=
                                        logLevel);
}

auto getUniqueSymbolsForTradingPaths(
    const std::vector<std::vector<Trade>> &tradingPaths)
    -> std::vector<std::string>
{
    std::unordered_set<std::string> uniqueSymbols{};
    for (const auto &path : tradingPaths)
    {
        for (const auto &trade : path)
        {
            uniqueSymbols.insert(trade.symbol()->symbol);
        }
    }
    return {uniqueSymbols.begin(), uniqueSymbols.end()};
}

auto main(int argc, char *argv[]) -> int
{
    banner();
    Configuration config;

    // config logging
    initLogging(config.getLogLevel());

    BOOST_LOG_TRIVIAL(info) << "Starting Harjus";

    // Set up SSL key logging for Wireshark TLS traffic decryption
    auto sslKeyLogFile = config.getSSLKeyLogFile();
    if (!sslKeyLogFile.empty())
    {
        FIX::ssl_set_keylog_file(sslKeyLogFile);
        BOOST_LOG_TRIVIAL(info) << "SSL key logging enabled, writing to: " << sslKeyLogFile;
    }

    // get balance, available symbols & relative values
    BOOST_LOG_TRIVIAL(debug) << "Getting balance";
    auto balance = getBalance(config);

    BOOST_LOG_TRIVIAL(debug) << "Getting symbols";
    auto symbolMap = getSymbols(config);

    BOOST_LOG_TRIVIAL(debug) << "Calculating relative values";
    auto relativeValueMap = getRelativeValues(config, symbolMap);

    // calculate trading paths
    BOOST_LOG_TRIVIAL(debug) << "Calculating trading paths";

    std::vector<std::vector<Trade>> tradingPaths;
    auto staticPaths = config.getStaticTradingPaths();

    if (!staticPaths.empty())
    {
        BOOST_LOG_TRIVIAL(info) << "Using static trading paths from configuration";
        for (const auto &path : staticPaths)
        {
            std::vector<Trade> tradePath;
            for (const auto &[symbolStr, position] : path)
            {
                if (symbolMap.find(symbolStr) == symbolMap.end())
                {
                    throw std::runtime_error("Symbol not found in symbol map: " + symbolStr);
                }
                tradePath.emplace_back(&symbolMap.at(symbolStr), position);
            }
            tradingPaths.push_back(tradePath);
        }
    }
    else
    {
        tradingPaths = getTradingPaths(symbolMap, config);
    }

    // Extract the list of symbols for subscription
    auto symbols = getUniqueSymbolsForTradingPaths(tradingPaths);

    // Log info of interest
    BOOST_LOG_TRIVIAL(info) << "There are " << symbolMap.size()
                            << " available trading symbols";

    if (config.getAssets().empty())
    {
        BOOST_LOG_TRIVIAL(info) << "Focusing on all assets ";
    }
    else
    {
        BOOST_LOG_TRIVIAL(info) << "Focusing only on " << config.getAssets().size()
                                << " assets";
    }

    BOOST_LOG_TRIVIAL(info) << "These form " << tradingPaths.size()
                            << " trading paths";

    BOOST_LOG_TRIVIAL(info) << "These consist of in total " << symbols.size()
                            << " trading symbols";

    // fix settings
    auto fixConfig = FixConfig(config);
    auto settings = fixConfig.sessionSettings();

    // Define a named constant for the queue size
    constexpr std::size_t QUEUE_SIZE = 1000;

    // Create queues for price updates & executions
    boost::lockfree::spsc_queue<PriceUpdate> priceUpdateQueue{QUEUE_SIZE};
    boost::lockfree::spsc_queue<ExecutionReport> reportQueue{QUEUE_SIZE};

    Application application{config, priceUpdateQueue, reportQueue, symbolMap, symbols, settings};
    FIX::MemoryStoreFactory storeFactory{};
    FIX::ScreenLogFactory logFactory{settings};

    auto initiator =
        FIX::FstackMicroThreadedSSLSocketInitiator{application, storeFactory, settings, logFactory, argc, argv};

    // Set the initiator pointer in the application so orders can be queued
    // for sending in the F-Stack microthread context
    application.setInitiator(&initiator);

    // Create the worker
    Worker worker{tradingPaths, priceUpdateQueue, reportQueue,
                  application, relativeValueMap, *balance,
                  config.getCommission()};

    // create a jthread to run worker
    std::jthread j_thread_worker(
        [&worker](const std::stop_token &stoken)
        { worker.run(stoken); });

    // create a jthread to run the initiator
    std::jthread j_thread_application([&initiator]()
                                      {
    BOOST_LOG_TRIVIAL(debug) << "Starting initiator thread";

    initiator.block(); });

    // wait for ctrl+c

    // Signal handler to set running to false on SIGINT or SIGTERM
    signal(SIGINT, [](int)
           { running = false; });
    signal(SIGTERM, [](int)
           { running = false; });

    BOOST_LOG_TRIVIAL(info) << "Worker thread started. Press Ctrl+C to exit.";

    constexpr int MAIN_LOOP_SLEEP_MS = 100;
    while (running)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(MAIN_LOOP_SLEEP_MS));
    }

    // remove signal handler for SIGINT
    signal(SIGINT, SIG_DFL);

    BOOST_LOG_TRIVIAL(info)
        << "Stopping threads... Press Ctrl+C to exit immediately.";

    // Stop the worker
    j_thread_worker.request_stop();
    j_thread_worker.join();

    // Stop the application
    isShuttingDown = true;
    initiator.stop();

    BOOST_LOG_TRIVIAL(info) << "Done. Exiting.";

    return 0;
}
