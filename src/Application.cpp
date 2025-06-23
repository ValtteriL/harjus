#include "Application.h"
#include "Ed25519.h"
#include "Position.h"
#include "PriceUpdate.h"
#include <atomic>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <quickfix/Field.h>
#include <quickfix/FieldTypes.h>
#include <quickfix/FixFields.h>
#include <quickfix/FixValues.h>
#include <quickfix/Session.h>
#include <quickfix/fix44/MarketDataRequestReject.h>
#include <quickfix/fix44/Reject.h>

extern std::atomic<bool> isShuttingDown;

Application::Application(
    const IConfiguration &conf, boost::lockfree::spsc_queue<PriceUpdate> &queue,
    boost::lockfree::spsc_queue<ExecutionReport> &reportQueue,
    std::unordered_map<std::string, Symbol> &symbolMap)
    : username(conf.getEd25519ApiKey()), privateKeySeed(conf.getEd25519Seed()),
      priceUpdateQueue(&queue), executionReportQueue(&reportQueue),
      symbolMap(&symbolMap) {}

void Application::onCreate(const FIX::SessionID &sessionID) {
  // store markert data session IDs if Qualifier starts with MARKETDATA
  if (sessionID.getSessionQualifier().starts_with("MARKETDATA")) {
    marketDataSessionIDs.push_back(sessionID);
  }
  // store order entry session ID if Qualifier is ORDERENTRY
  else if (sessionID.getSessionQualifier() == "ORDERENTRY") {
    orderEntrySessionID = sessionID;
  }
}

void Application::onLogon(const FIX::SessionID &sessionID) {
  BOOST_LOG_TRIVIAL(debug) << "FIX logon - " << sessionID;
}

void Application::onLogout(const FIX::SessionID &sessionID) {
  BOOST_LOG_TRIVIAL(debug) << "FIX logout - " << sessionID;
  if (!isShuttingDown) {
    throw std::runtime_error("FIX session disconnected abnormally: " +
                             sessionID.toString());
  }
}

void Application::fromAdmin(const FIX::Message &message, const FIX::SessionID &)
    EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue,
           FIX::RejectLogon) {

  FIX::MsgType msgType;
  message.getHeader().getField(msgType);

  if (msgType == FIX::MsgType_Reject) {
    throw std::runtime_error("Received Reject message: " + message.toString());
  }
}

void Application::toAdmin(FIX::Message &message,
                          const FIX::SessionID &sessionID) {
  FIX::MsgType msgType;
  message.getHeader().getField(msgType);

  // Binance requires username and password in the logon message
  if (msgType.getValue() == FIX::MsgType_Logon) {
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
           FIX::UnsupportedMessageType) {
  crack(message, sessionID); // crack the message to the appropriate handler
}

void Application::toApp(FIX::Message &message, const FIX::SessionID &)
    EXCEPT(FIX::DoNotSend) {
  try {
    FIX::PossDupFlag possDupFlag;
    message.getHeader().getField(possDupFlag);
    if (possDupFlag) {
      throw FIX::DoNotSend();
    }
  } catch (FIX::FieldNotFound &) {
  }
}

bool Application::subscribeToSymbols(const std::vector<std::string> &symbols) {
  if (marketDataSessionIDs.empty()) {
    throw std::runtime_error(
        "No market data sessions available for subscription");
  }

  // check at least one session for every 1000 symbols
  if (marketDataSessionIDs.size() < symbols.size() / 1000) {
    throw std::runtime_error(
        "Not enough market data sessions available for subscription");
  }

  // Split symbols into chunks for each market data session
  // Distribute symbols evenly across sessions

  size_t numSessions = marketDataSessionIDs.size();
  size_t totalSymbols = symbols.size();
  size_t symbolsPerSession = totalSymbols / numSessions;
  size_t remainder = totalSymbols % numSessions;

  try {
    size_t symbolIndex = 0;
    for (size_t i = 0; i < numSessions; ++i) {
      size_t numSymbolsForThisSession =
          symbolsPerSession + (i < remainder ? 1 : 0);
      if (numSymbolsForThisSession == 0)
        continue; // Skip if no symbols for this session

      // Get the chunk of symbols for this session
      auto startIt = symbols.begin() + symbolIndex;
      auto endIt = startIt + numSymbolsForThisSession;
      std::vector<std::string> chunk(startIt, endIt);
      symbolIndex += numSymbolsForThisSession;

      FIX44::MarketDataRequest marketDataRequest;

      // Generate a unique request ID for this session's request
      std::string reqId = "MDReq-" + std::to_string(std::time(nullptr)) + "-" +
                          std::to_string(i);
      marketDataRequest.set(FIX::MDReqID(reqId));

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
      for (const auto &symbol : chunk) {
        symbolGroup.set(FIX::Symbol(symbol));
        marketDataRequest.addGroup(symbolGroup);
      }

      // Send the request to the corresponding market data session
      FIX::Session::sendToTarget(marketDataRequest, marketDataSessionIDs[i]);
    }
    return true;
  } catch (const std::exception &e) {
    throw std::runtime_error("Error sending market data request: " +
                             std::string(e.what()));
  }
}

void Application::onMessage(const FIX44::ExecutionReport &message,
                            const FIX::SessionID &) {
  try {

    // Extract the ClOrdID
    FIX::ClOrdID clOrdID;
    message.get(clOrdID);
    std::string id = clOrdID.getValue();

    // Get execution type
    FIX::ExecType execType;
    message.get(execType);
    char execTypeValue = execType.getValue();

    // Determine the execution status based on ExecType
    TradeExecutionStatus status;
    switch (execTypeValue) {
    case FIX::ExecType_NEW:
      return; // Ignore notification of new order
    case FIX::ExecType_TRADE:
      status = TradeExecutionStatus::FILLED;
      break;
    case FIX::ExecType_EXPIRED:
      status = TradeExecutionStatus::EXPIRED;
      break;
    case FIX::ExecType_REJECTED: {
      status = TradeExecutionStatus::REJECTED;
      // Extract the human readable error message (Text field)
      FIX::Text textField;
      std::string errorMsg;
      if (message.isSetField(FIX::FIELD::Text)) {
        message.get(textField);
        errorMsg = textField.getValue();
      } else {
        errorMsg = "Unknown error (Text field not set)";
      }

      // if doesnt contain "insufficient balance"
      if (errorMsg.find("insufficient balance") == std::string::npos) {
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
    message.get(cumQty);
    PreciseNumber qtyBase = PreciseNumber{cumQty.getString()};

    FIX::QtyField cumQuoteQty(
        25017); // Total number of quote asset traded on this order.
    message.getField(cumQuoteQty);
    PreciseNumber qtyQuote = PreciseNumber{cumQuoteQty.getString()};

    FIX::Side side;
    message.get(side);
    Position position =
        (side == FIX::Side_BUY) ? Position::LONG : Position::SHORT;

    auto usedQty = position == Position::LONG ? qtyQuote : qtyBase;
    auto recvQty = position == Position::LONG ? qtyBase : qtyQuote;

    // Create asset delta map
    std::unordered_map<std::string, PreciseNumber> feeDelta;

    // Extract the fees from the message into the asset delta map
    int numMiscFees = 0;
    if (FIX::NoMiscFees noMiscFees;
        message.isSetField(FIX::FIELD::NoMiscFees)) {
      message.get(noMiscFees);
      numMiscFees = noMiscFees.getValue();
    }

    for (int i = 1; i <= numMiscFees; i++) {
      FIX44::ExecutionReport::NoMiscFees group;
      message.getGroup(i, group);

      FIX::MiscFeeType feeType;
      group.get(feeType);

      // Only process fees of type "Exchange Fees" (4)
      if (feeType == FIX::MiscFeeType_EXCHANGE_FEES) {
        FIX::MiscFeeCurr feeCurrency;
        group.get(feeCurrency);
        std::string currency = feeCurrency.getValue();

        FIX::MiscFeeAmt feeAmount;
        group.get(feeAmount);

        // Add the fee amount to the asset delta map
        feeDelta[currency] -= PreciseNumber{feeAmount.getString()};
      }
    }

    // Create execution report & push to the queue
    executionReportQueue.push(
        ExecutionReport{id, status, usedQty, recvQty, feeDelta});

  } catch (const std::exception &e) {

    throw std::runtime_error("Error processing execution report: " +
                             std::string(e.what()));
  }
}

void Application::onMessage(const FIX44::MarketDataRequestReject &message,
                            const FIX::SessionID &) {
  throw std::runtime_error("Market Data Request Rejected: " +
                           message.toString());
}

void Application::onMessage(const FIX44::MarketDataSnapshotFullRefresh &message,
                            const FIX::SessionID &) {
  try {
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

    for (int i = 1; i <= numEntries; i++) {
      FIX44::MarketDataSnapshotFullRefresh::NoMDEntries group;
      message.getGroup(i, group);

      FIX::MDEntryType entryType;
      group.get(entryType);

      // Process bid (0) or ask (1) entries
      if (entryType == FIX::MDEntryType_BID) {
        FIX::MDEntryPx entryPrice;
        FIX::MDEntrySize entrySize;

        group.get(entryPrice);
        group.get(entrySize);

        bidPrice = PreciseNumber{entryPrice.getString()};
        bidQuantity = PreciseNumber{entrySize.getString()};
      } else if (entryType == FIX::MDEntryType_OFFER) {
        FIX::MDEntryPx entryPrice;
        FIX::MDEntrySize entrySize;

        group.get(entryPrice);
        group.get(entrySize);

        askPrice = PreciseNumber{entryPrice.getString()};
        askQuantity = PreciseNumber{entrySize.getString()};
      }
    }

    priceUpdateQueue.push(PriceUpdate{&symbolMap->at(symbolValue), bidPrice,
                                      askPrice, bidQuantity, askQuantity});
  } catch (const std::exception &e) {
    throw std::runtime_error("Error processing market data snapshot: " +
                             std::string(e.what()));
  }
}

void Application::onMessage(const FIX44::MarketDataIncrementalRefresh &message,
                            const FIX::SessionID &) {
  try {
    // Check if we have any MD entries
    FIX::NoMDEntries noMDEntries;
    message.get(noMDEntries);
    int numEntries = noMDEntries.getValue();

    // We may get updates for multiple symbols in a single message
    std::map<std::string, PriceUpdate> updates;

    // symbol may be skipped in which case we need to use the last one
    FIX::Symbol symbol;

    for (int i = 1; i <= numEntries; i++) {
      FIX44::MarketDataIncrementalRefresh::NoMDEntries group;
      message.getGroup(i, group);

      FIX::MDEntryType entryType;
      group.get(entryType);

      // symbol is the same as previous group if not set
      if (group.isSetField(FIX::FIELD::Symbol)) {
        group.get(symbol);
      }

      std::string symbolValue = symbol.getValue();

      // Check if we already have an update for this symbol
      if (updates.find(symbolValue) == updates.end()) {
        // Create a new update
        updates[symbolValue].symbol = &symbolMap->at(symbolValue);
      }

      // Process update based on entry type (bid or ask)
      FIX::MDUpdateAction action;
      group.get(action);

      // Only process "New" or "Change" actions (0 or 1)
      if (action.getValue() == FIX::MDUpdateAction_NEW ||
          action.getValue() == FIX::MDUpdateAction_CHANGE) {
        FIX::MDEntryPx entryPrice;
        group.get(entryPrice);

        if (group.isSetField(FIX::FIELD::MDEntrySize)) {
          FIX::MDEntrySize entrySize;
          group.get(entrySize);

          if (entryType == FIX::MDEntryType_BID) {
            updates[symbolValue].bidPrice =
                PreciseNumber{entryPrice.getString()};
            updates[symbolValue].bidQty = PreciseNumber{entrySize.getString()};
          } else if (entryType == FIX::MDEntryType_OFFER) {
            updates[symbolValue].askPrice =
                PreciseNumber{entryPrice.getString()};
            updates[symbolValue].askQty = PreciseNumber{entrySize.getString()};
          }
        }
      }
    }

    // Add all updates to the queue
    for (const auto &[symbol, update] : updates) {
      priceUpdateQueue->push(update);
    }
  } catch (const std::exception &e) {
    throw std::runtime_error("Error processing incremental refresh: " +
                             std::string(e.what()));
  }
}

void onMessage(const FIX::Message &message, const FIX::SessionID &) {
  // Handle all unhandled message types
  throw std::runtime_error("Received unexpected message: " +
                           message.toString());
}

void Application::submitOrder(const std::string &id, const std::string &symbol,
                              PreciseNumber qty, PreciseNumber price,
                              Position position) {
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

  // Send the order to the order entry session
  FIX::Session::sendToTarget(newOrder, orderEntrySessionID);
}
