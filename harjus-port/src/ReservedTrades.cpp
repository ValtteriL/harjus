#include "ReservedTrades.h"

void ReservedTrades::reserve(ITrade &trade)
{
  reservedTrades.insert(&trade);
}

void ReservedTrades::release(ITrade &trade)
{
  reservedTrades.erase(&trade);
}

bool ReservedTrades::isReserved(ITrade &trade) const
{
  return reservedTrades.contains(&trade);
}
