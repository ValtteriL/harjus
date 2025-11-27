/*
 * ReservedTradesTest.cpp
 * Testing the reserved symbols.
 */

#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <algorithm>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
using ::testing::Return;
using ::testing::ReturnRef;

/**
 * Test fixture for ReservedTrades.
 */

class ReservedTradesTest : public testing::Test
{
protected:
    ReservedTradesTest() = default;

    // trade1 and trade2 are identical trades
    // trade3 is a different (different position)
    Symbol symbol{
        "BTCETH",                // symbol;
        "BTC",                   // baseAsset;
        "ETH",                   // quoteAsset;
        PreciseNumber{"0.0001"}, // minNotional;
        PreciseNumber{"0.0001"}, // baseAssetIncrement;
        PreciseNumber{"0.0001"}, // quoteAssetIncrement;
        8,                       // baseAssetPrecision;
        8,                       // quoteAssetPrecision;
        PreciseNumber{"0.0"},    // bidPrice;
        PreciseNumber{"1.0"},    // askPrice;
        PreciseNumber{"0.0"},    // bidQty;
        PreciseNumber{"100.0"}   // askQty;
    };
    Trade trade1{&symbol, Position::LONG};
    Trade trade2{&symbol, Position::LONG};
    Trade trade3{&symbol, Position::SHORT};
    ReservedTrades reservedTrades;
};

TEST_F(ReservedTradesTest, checkReserveCheckReleaseCheck)
{
    EXPECT_TRUE(reservedTrades.getReservedTrades().size() == 0);

    std::vector<Trade> trades{trade1};
    reservedTrades.reserveAll(trades);

    EXPECT_EQ(reservedTrades.getReservedTrades().size(), 1);
}

TEST_F(ReservedTradesTest, reserveCheckIdenticalTrade)
{
    std::vector<Trade> trades{trade1};
    reservedTrades.reserveAll(trades);

    auto reservedTradesSet = reservedTrades.getReservedTrades();

    EXPECT_TRUE(reservedTradesSet.contains(trade1.symbol()->symbol));
    EXPECT_TRUE(reservedTradesSet.contains(trade2.symbol()->symbol));
}

TEST_F(ReservedTradesTest, reserveCheckTradeWithSameSymbol)
{
    std::vector<Trade> trades{trade1};
    reservedTrades.reserveAll(trades);

    auto reservedTradesSet = reservedTrades.getReservedTrades();
    EXPECT_TRUE(reservedTradesSet.contains(trade3.symbol()->symbol));
}

TEST_F(ReservedTradesTest, releaseAll)
{
    std::vector<Trade> trades{trade1, trade2};
    reservedTrades.reserveAll(trades);

    auto reservedTradesSet = reservedTrades.getReservedTrades();

    EXPECT_TRUE(reservedTradesSet.contains(trade1.symbol()->symbol));
    EXPECT_TRUE(reservedTradesSet.contains(trade2.symbol()->symbol));

    std::vector<StaticTrade> staticTrades{trade1, trade2};

    reservedTrades.releaseAll(staticTrades);

    auto reservedTradesSetAfterRelease = reservedTrades.getReservedTrades();
    EXPECT_TRUE(reservedTradesSetAfterRelease.empty());
}

// test isReserved with vector of trades
TEST_F(ReservedTradesTest, isReservedWithVector)
{

    std::vector<Trade> trades{trade1, trade2, trade3};

    auto reservedTradesSet = reservedTrades.getReservedTrades();
    EXPECT_TRUE(reservedTradesSet.empty());

    std::vector<Trade> reserveTrades{trade1};
    reservedTrades.reserveAll(reserveTrades);

    auto reservedTradesAfterReserve = reservedTrades.getReservedTrades();

    EXPECT_TRUE(
        std::all_of(trades.begin(), trades.end(),
                    [&reservedTradesAfterReserve](const Trade &trade)
                    {
                        return reservedTradesAfterReserve.contains(
                            trade.symbol()->symbol);
                    }));
}