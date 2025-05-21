#pragma once

#include "Balance.h"
#include "IConfiguration.h"
#include "PreciseNumber.h"
#include "Symbol.h"
#include <memory>
#include <unordered_map>

/**
 * @file Exchange.h
 * @brief Exchange class. Contains logic for fetching exchange information and
 * prices.
 * @details This class is used to fetch exchange information and prices from the
 * exchange API.
 */

/**
 * @brief Fetches current balance from the exchange API.
 * @param config Configuration object containing API keys and other settings.
 * @return Balance object containing the current balance.
 */
std::unique_ptr<Balance> getBalance(IConfiguration &config);

/**
 * @brief Fetches symbol information from the exchange API.
 * @details This function fetches symbol information from the exchange API and
 * constructs a map from the symbols to their corresponding Symbol objects.
 * The map is used to store information about each symbol, including its
 * trading pair, base asset, quote asset, and other relevant details. The
 * symbols are manually allocated and should be deleted by the caller to avoid
 * memory leaks.
 * @param config Configuration object containing API keys and other settings.
 * @return A map of symbol names to Symbol objects containing symbol
 * information.
 */
std::unordered_map<std::string, Symbol *> getSymbols(IConfiguration &config);

/**
 * @brief Fetches relative values of symbols in Bitcoin from the exchange API.
 * @param config Configuration object containing API keys and other settings.
 * @param symbols A map of symbol names to Symbol objects containing symbol
 * information.
 * @return A map of symbol names to their relative values in Bitcoin.
 */
std::unordered_map<std::string, PreciseNumber>
getRelativeValues(IConfiguration &config,
                  const std::unordered_map<std::string, Symbol *> &symbols);
