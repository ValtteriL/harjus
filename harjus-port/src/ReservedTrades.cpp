#include "ReservedTrades.h"

void ReservedTrades::reserve(const Trade &trade)
{
  reservedTrades.insert(trade);
}

void ReservedTrades::release(const Trade &trade)
{
  reservedTrades.erase(trade);
}

bool ReservedTrades::isReserved(const Trade &trade) const
{
  return reservedTrades.contains(trade);
}
