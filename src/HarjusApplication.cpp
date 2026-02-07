#include "HarjusApplication.h"
#include "Ed25519.h"
#include "ExecutionReport.h"
#include "Globals.h"
#include "Position.h"
#include "PriceUpdate.h"
#include "SessionID.h"
#include <Field.h>
#include <FieldTypes.h>
#include <FixFields.h>
#include <FixValues.h>
#include <Session.h>
#include <atomic>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <cstddef>
#include <fix44/MarketDataRequestReject.h>
#include <fix44/Reject.h>
#include <vector>

extern std::atomic<bool> isShuttingDown;

Application::Application(
    const IConfiguration &conf,
    boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
    boost::lockfree::spsc_queue<ExecutionReport> &executionReportQueue,
    std::unordered_map<std::string, Symbol> &symbolMap,
    const std::vector<std::string> &symbols, const FIX::SessionSettings &settings)
    : username(conf.getEd25519ApiKey()), privateKeySeed(conf.getEd25519Seed()),
      symbolMap(&symbolMap), symbols(symbols), priceUpdateQueue(&priceUpdateQueue),
      executionReportQueue(&executionReportQueue), sessionSettings(settings)
{
    // Divide symbols between market data sessions
    auto sessions = sessionSettings.getSessions();
    std::erase_if(sessions, [](const FIX::SessionID &x)
                  { return x.getSessionQualifier().starts_with("MARKETDATA") == false; });

    // ensure at least one market data session for every 1000 symbols
    if (sessions.size() < symbols.size() / 1000)
    {
        throw std::runtime_error(
            "Not enough market data sessions available for subscription");
    }

    auto dividedSymbols = divideSymbolsEvenly(symbols, sessions.size());

    int index = 0;
    for (const auto &sessionID : sessions)
    {
        marketSessionQualifierToSymbolsMap[sessionID.getSessionQualifier()] = dividedSymbols[index];
        index++;
    }
}

auto Application::divideSymbolsEvenly(const std::vector<std::string> &symbols,
                                      size_t numSessions)
    -> std::vector<std::vector<std::string>>
{
    std::vector<std::vector<std::string>> dividedSymbols;
    size_t totalSymbols = symbols.size();
    size_t symbolsPerSession = totalSymbols / numSessions;
    size_t remainder = totalSymbols % numSessions;

    size_t symbolIndex = 0;
    for (size_t i = 0; i < numSessions; i++)
    {
        size_t numSymbolsForThisSession =
            symbolsPerSession + (i < remainder ? 1 : 0);
        dividedSymbols.emplace_back();
        for (size_t j = 0; j < numSymbolsForThisSession; j++)
        {
            dividedSymbols.at(i).push_back(symbols.at(symbolIndex++));
        }
    }
    return dividedSymbols;
}

void Application::onCreate(const FIX::SessionID &sessionID)
{
    // store order entry session ID if Qualifier is ORDERENTRY
    if (sessionID.getSessionQualifier() == "ORDERENTRY")
    {
        orderEntrySessionID = sessionID;
    }
}

void Application::onLogon(const FIX::SessionID &sessionID)
{
    BOOST_LOG_TRIVIAL(debug) << "FIX logon - " << sessionID;

    auto sessionQualifier = sessionID.getSessionQualifier();

    // subscribe to symbols for market data sessions
    if (sessionQualifier.starts_with("MARKETDATA"))
    {
        subscribeMarketSessionToSymbols(sessionID, marketSessionQualifierToSymbolsMap.at(sessionQualifier));
    }
}

void Application::onLogout(const FIX::SessionID &sessionID)
{
    BOOST_LOG_TRIVIAL(debug) << "FIX logout - " << sessionID;
    if (!isShuttingDown)
    {
        throw std::runtime_error("FIX session disconnected abnormally: " +
                                 sessionID.toString());
    }
}

void Application::fromAdmin(const FIX::Message &message, const FIX::SessionID &)
    EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue,
           FIX::RejectLogon)
{

    FIX::MsgType msgType;
    message.getHeader().getField(msgType);

    if (msgType.getValue() == FIX::MsgType_Reject)
    {
        throw std::runtime_error("Received Reject message: " + message.toString());
    }
}

void Application::toAdmin(FIX::Message &message,
                          const FIX::SessionID &sessionID)
{
    FIX::MsgType msgType;
    message.getHeader().getField(msgType);

    // Binance requires username and password in the logon message
    if (msgType.getValue() == FIX::MsgType_Logon)
    {
        FIX::Header &header = message.getHeader();

        // add required fields to the header
        header.setField(
            FIX::IntField(25035, 2)); // sequential processing of messages

        // set username
        header.setField(FIX::Username(username.c_str()));

        // The signature payload is a text string constructed by concatenating the
        // values of the following fields in this exact order, separated by the SOH
        // character:
        // 1. 35 (MsgType)
        // 2. 49 (SenderCompID)
        // 3. 56 (TargetCompID)
        // 4. 34 (MsgSeqNum)
        // 5. 52 (SendingTime)
        std::string payload = msgType.getValue() + '\x01' +
                              header.getField(FIX::SenderCompID().getTag()) +
                              '\x01' +
                              header.getField(FIX::TargetCompID().getTag()) +
                              '\x01' + header.getField(FIX::MsgSeqNum().getTag()) +
                              '\x01' + header.getField(FIX::SendingTime().getTag());

        // set password (Binance expects password in RawData field)
        std::string password = Ed25519::sign(privateKeySeed, payload);
        header.setField(FIX::RawData(password.c_str()));
        header.setField(FIX::RawDataLength(password.length()));

        BOOST_LOG_TRIVIAL(debug) << "Sending logon request - " << sessionID;
    }
}

void Application::fromApp(const FIX::Message &message,
                          const FIX::SessionID &sessionID)
    EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue,
           FIX::UnsupportedMessageType)
{
    crack(message, sessionID); // crack the message to the appropriate handler
}

void Application::toApp(FIX::Message &message, const FIX::SessionID &)
    EXCEPT(FIX::DoNotSend)
{
    try
    {
        FIX::PossDupFlag possDupFlag;
        message.getHeader().getField(possDupFlag);
        if (possDupFlag)
        {
            throw FIX::DoNotSend();
        }
    }
    catch (FIX::FieldNotFound &)
    {
    }
}

auto Application::subscribeMarketSessionToSymbols(FIX::SessionID sessionID, const std::vector<std::string> &symbols)
    -> bool
{
    if (symbols.empty())
    {
        BOOST_LOG_TRIVIAL(warning)
            << "No symbols to subscribe for session " << sessionID.toString();
        return true;
    }

    try
    {

        FIX44::MarketDataRequest marketDataRequest;

        // Generate a unique request ID for this session's request
        std::string reqId = "MDReq-" + std::to_string(std::time(nullptr));
        marketDataRequest.set(FIX::MDReqID(reqId));

        BOOST_LOG_TRIVIAL(debug)
            << "Subscribing to " << symbols.size() << " symbols" << " on session " << sessionID.toString()
            << " with ReqID " << reqId;

        // Set subscription type (1 = Subscribe)
        marketDataRequest.set(FIX::SubscriptionRequestType(
            FIX::SubscriptionRequestType_SNAPSHOT_AND_UPDATES));

        // Set market depth
        marketDataRequest.set(FIX::MarketDepth(1)); // 1 = Top of book

        // Create NoMDEntryTypes group for requesting BID and OFFER
        FIX44::MarketDataRequest::NoMDEntryTypes entryTypeGroup;

        // Add BID entry type (0)
        entryTypeGroup.set(FIX::MDEntryType(FIX::MDEntryType_BID));
        marketDataRequest.addGroup(entryTypeGroup);

        // Add OFFER entry type (1)
        entryTypeGroup.set(FIX::MDEntryType(FIX::MDEntryType_OFFER));
        marketDataRequest.addGroup(entryTypeGroup);

        // Add all symbols in the current chunk
        FIX44::MarketDataRequest::NoRelatedSym symbolGroup; // Reuse group object
        for (const auto &symbol : symbols)
        {
            symbolGroup.set(FIX::Symbol(symbol));
            marketDataRequest.addGroup(symbolGroup);
        }

        // Send the request to the corresponding market data session
        FIX::Session::sendToTarget(marketDataRequest, sessionID);

        return true;
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Error sending market data request: " +
                                 std::string(e.what()));
    }
}

auto parseExecutionReport(const FIX44::ExecutionReport &execReport)
    -> ExecutionReport
{

    // Extract the ClOrdID
    FIX::ClOrdID clOrdID;
    execReport.get(clOrdID);
    std::string id = clOrdID.getValue();

    // Get execution type
    FIX::ExecType execType;
    execReport.get(execType);
    char execTypeValue = execType.getValue();

    // Determine the execution status based on ExecType
    TradeExecutionStatus status{};
    switch (execTypeValue)
    {
    case FIX::ExecType_NEW:
        status = TradeExecutionStatus::NEW;
        break;
    case FIX::ExecType_TRADE:
        status = TradeExecutionStatus::FILLED;
        break;
    case FIX::ExecType_EXPIRED:
        status = TradeExecutionStatus::EXPIRED;
        break;
    case FIX::ExecType_REJECTED:
    {
        status = TradeExecutionStatus::REJECTED;
        // Extract the human readable error message (Text field)
        FIX::Text textField;
        std::string errorMsg;
        if (execReport.isSetField(FIX::FIELD::Text))
        {
            execReport.get(textField);
            errorMsg = textField.getValue();
        }
        else
        {
            errorMsg = "Unknown error (Text field not set)";
        }

        // if doesnt contain "insufficient balance"
        if (errorMsg.find("insufficient balance") == std::string::npos)
        {
            throw std::runtime_error("Order rejected for unexpected reason: " +
                                     errorMsg);
        }
        break;
    }
    default:
        // For other cases, just log and return without creating execution report

        throw std::runtime_error(
            "Received ExecutionReport with unhandled ExecType: " +
            std::to_string(execTypeValue));
    }

    // Extract the used and received quantities
    FIX::CumQty cumQty; // Total number of base asset traded on this order.
    execReport.get(cumQty);
    PreciseNumber qtyBase = PreciseNumber{cumQty.getString()};

    FIX::QtyField cumQuoteQty(
        25017); // Total number of quote asset traded on this order.
    execReport.getField(cumQuoteQty);
    PreciseNumber qtyQuote = PreciseNumber{cumQuoteQty.getString()};

    FIX::Side side;
    execReport.get(side);
    Position position =
        (side == FIX::Side_BUY) ? Position::LONG : Position::SHORT;

    auto usedQty = position == Position::LONG ? qtyQuote : qtyBase;
    auto recvQty = position == Position::LONG ? qtyBase : qtyQuote;

    // Create asset delta map
    std::unordered_map<std::string, PreciseNumber> feeDelta;

    // Extract the fees from the message into the asset delta map
    int numMiscFees = 0;
    if (FIX::NoMiscFees noMiscFees;
        execReport.isSetField(FIX::FIELD::NoMiscFees))
    {
        execReport.get(noMiscFees);
        numMiscFees = noMiscFees.getValue();
    }

    for (int i = 1; i <= numMiscFees; i++)
    {
        FIX44::ExecutionReport::NoMiscFees group;
        execReport.getGroup(i, group);

        FIX::MiscFeeType feeType;
        group.get(feeType);

        // Only process fees of type "Exchange Fees" (4)
        if (feeType == FIX::MiscFeeType_EXCHANGE_FEES)
        {
            FIX::MiscFeeCurr feeCurrency;
            group.get(feeCurrency);
            std::string currency = feeCurrency.getValue();

            FIX::MiscFeeAmt feeAmount;
            group.get(feeAmount);

            // Add the fee amount to the asset delta map
            feeDelta[currency] -= PreciseNumber{feeAmount.getString()};
        }
    }

    return ExecutionReport{id, status, usedQty, recvQty, feeDelta};
}

void Application::onMessage(const FIX44::ExecutionReport &message,
                            const FIX::SessionID &)
{
    auto execReport = parseExecutionReport(message);
    executionReportQueue->push(execReport);
}

void Application::onMessage(const FIX44::MarketDataRequestReject &message,
                            const FIX::SessionID &)
{
    throw std::runtime_error("Market Data Request Rejected: " +
                             message.toString());
}

auto Application::parsePriceUpdateFromMarketDataSnapshotFullRefresh(
    const FIX44::MarketDataSnapshotFullRefresh &message)
    -> PriceUpdate
{

    FIX::Symbol symbol;

    message.get(symbol);

    std::string symbolValue = symbol.getValue();

    // We need variables to store best bid/ask data
    PreciseNumber bidPrice{};
    PreciseNumber bidQuantity{};
    PreciseNumber askPrice{};
    PreciseNumber askQuantity{};

    FIX::NoMDEntries noMDEntries;
    message.get(noMDEntries);
    int numEntries = noMDEntries.getValue();

    for (int i = 1; i <= numEntries; i++)
    {
        FIX44::MarketDataSnapshotFullRefresh::NoMDEntries group;
        message.getGroup(i, group);

        FIX::MDEntryType entryType;
        group.get(entryType);

        // Process bid (0) or ask (1) entries
        if (entryType == FIX::MDEntryType_BID)
        {
            FIX::MDEntryPx entryPrice;
            FIX::MDEntrySize entrySize;

            group.get(entryPrice);
            group.get(entrySize);

            bidPrice = PreciseNumber{entryPrice.getString()};
            bidQuantity = PreciseNumber{entrySize.getString()};
        }
        else if (entryType == FIX::MDEntryType_OFFER)
        {
            FIX::MDEntryPx entryPrice;
            FIX::MDEntrySize entrySize;

            group.get(entryPrice);
            group.get(entrySize);

            askPrice = PreciseNumber{entryPrice.getString()};
            askQuantity = PreciseNumber{entrySize.getString()};
        }
    }

    return PriceUpdate{&symbolMap->at(symbolValue), bidPrice,
                       askPrice, bidQuantity, askQuantity};
}

void Application::onMessage(const FIX44::MarketDataSnapshotFullRefresh &message,
                            const FIX::SessionID &)
{
    auto priceUpdate =
        parsePriceUpdateFromMarketDataSnapshotFullRefresh(message);
    priceUpdateQueue->push(priceUpdate);
}

auto Application::parsePriceUpdateFromMarketDataIncrementalRefresh(
    const FIX44::MarketDataIncrementalRefresh &message)
    -> std::vector<PriceUpdate>
{

    // Check if we have any MD entries
    FIX::NoMDEntries noMDEntries;
    message.get(noMDEntries);
    int numEntries = noMDEntries.getValue();

    std::vector<PriceUpdate> priceUpdates{};

    // We may get updates for multiple symbols in a single message
    std::map<std::string, size_t> updates;

    // symbol may be skipped in which case we need to use the last one
    FIX::Symbol symbol;

    for (int i = 1; i <= numEntries; i++)
    {
        FIX44::MarketDataIncrementalRefresh::NoMDEntries group;
        message.getGroup(i, group);

        FIX::MDEntryType entryType;
        group.get(entryType);

        // symbol is the same as previous group if not set
        if (group.isSetField(FIX::FIELD::Symbol))
        {
            group.get(symbol);
        }

        std::string symbolValue = symbol.getValue();

        // Check if we already have an update for this symbol
        if (updates.find(symbolValue) == updates.end())
        {
            // Create a new update, store its index
            priceUpdates.push_back(PriceUpdate{&symbolMap->at(symbolValue), {}, {}, {}, {}});
            updates[symbolValue] = priceUpdates.size() - 1;
        }

        // Process update based on entry type (bid or ask)
        FIX::MDUpdateAction action;
        group.get(action);

        // Only process "New" or "Change" actions (0 or 1)
        if (action.getValue() == FIX::MDUpdateAction_NEW ||
            action.getValue() == FIX::MDUpdateAction_CHANGE)
        {
            FIX::MDEntryPx entryPrice;
            group.get(entryPrice);

            if (group.isSetField(FIX::FIELD::MDEntrySize))
            {
                FIX::MDEntrySize entrySize;
                group.get(entrySize);

                if (entryType == FIX::MDEntryType_BID)
                {
                    priceUpdates[updates[symbolValue]].bidPrice =
                        PreciseNumber{entryPrice.getString()};

                    priceUpdates[updates[symbolValue]].bidQty = PreciseNumber{entrySize.getString()};
                }
                else if (entryType == FIX::MDEntryType_OFFER)
                {
                    priceUpdates[updates[symbolValue]].askPrice =
                        PreciseNumber{entryPrice.getString()};
                    priceUpdates[updates[symbolValue]].askQty = PreciseNumber{entrySize.getString()};
                }
            }
        }
    }

    return priceUpdates;
}

void Application::onMessage(const FIX44::MarketDataIncrementalRefresh &message,
                            const FIX::SessionID &)
{

    auto priceUpdates =
        parsePriceUpdateFromMarketDataIncrementalRefresh(message);
    for (auto &update : priceUpdates)
    {
        priceUpdateQueue->push(update);
    }
}

void Application::submitOrder(const std::string &id, const std::string &symbol,
                              PreciseNumber qty, PreciseNumber price,
                              Position position)
{
    FIX44::NewOrderSingle newOrder;

    newOrder.set(FIX::ClOrdID(id));
    newOrder.set(FIX::OrdType(FIX::OrdType_LIMIT));
    newOrder.set(
        FIX::Side(position == Position::LONG ? FIX::Side_BUY : FIX::Side_SELL));
    newOrder.set(FIX::Symbol(symbol));

    // Get the tag number for OrderQty without constructing the field
    newOrder.setField(FIX::FIELD::OrderQty, qty.toString());
    newOrder.setField(FIX::FIELD::Price, price.toString());

    newOrder.set(FIX::TimeInForce(FIX::TimeInForce_FILL_OR_KILL));

    // Queue the order to be sent in the F-Stack microthread context.
    // Direct calls to Session::sendToTarget from the Worker thread would fail
    // because F-Stack socket operations require the microthread frame to be
    // initialized on the calling thread.
    if (initiator != nullptr)
    {
        initiator->queueMessage(newOrder, orderEntrySessionID);
    }
}
