#include "Application.h"
#include "Ed25519.h"
#include <quickfix/Session.h>
#include <iostream>
#include <sstream>

void Application::onLogon(const FIX::SessionID &sessionID)
{
  std::cout << std::endl
            << "Logon - " << sessionID << std::endl;
}

void Application::onLogout(const FIX::SessionID &sessionID)
{
  std::cout << std::endl
            << "Logout - " << sessionID << std::endl;
}

void Application::toAdmin(FIX::Message &message, const FIX::SessionID &)
{
  FIX::MsgType msgType;
  message.getHeader().getField(msgType);

  // Binance requires username and password in the logon message
  if (msgType.getValue() == FIX::MsgType_Logon)
  {
    FIX::Header &header = message.getHeader();

    // set username
    header.setField(FIX::Username(username.c_str()));
    header.setField(FIX::RawDataLength(username.length()));

    // set password (Binance expects password in RawData field)
    std::string password = Ed25519::sign(privateKeySeed, message.toString());
    header.setField(FIX::RawData(password.c_str()));
    header.setField(FIX::RawDataLength(password.length()));
  }
}

void Application::fromApp(const FIX::Message &message, const FIX::SessionID &sessionID)
    EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue, FIX::UnsupportedMessageType)
{
  crack(message, sessionID); // crack the message to the appropriate handler
  std::cout << std::endl
            << "IN: " << message << std::endl;
}

void Application::toApp(FIX::Message &message, const FIX::SessionID &) EXCEPT(FIX::DoNotSend)
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

  std::cout << std::endl
            << "OUT: " << message << std::endl;
}

bool Application::subscribeToSymbols(const std::vector<std::string> &symbols)
{
  if (marketDataSessionID == FIX::SessionID())
  {
    std::cerr << "No market data session available" << std::endl;
    return false;
  }

  try
  {
    FIX44::MarketDataRequest marketDataRequest;

    // Generate a unique request ID
    std::string reqId = "MDReq-" + std::to_string(std::time(nullptr));
    marketDataRequest.set(FIX::MDReqID(reqId));

    // Set subscription type (1 = Subscribe)
    marketDataRequest.set(FIX::SubscriptionRequestType('1'));

    // Set market depth
    marketDataRequest.set(FIX::MarketDepth('1'));

    // Create NoMDEntryTypes group for requesting BID and OFFER
    FIX44::MarketDataRequest::NoMDEntryTypes entryTypeGroup;

    // Add BID entry type (0)
    entryTypeGroup.set(FIX::MDEntryType('0'));
    marketDataRequest.addGroup(entryTypeGroup);

    // Add OFFER entry type (1)
    entryTypeGroup.set(FIX::MDEntryType('1'));
    marketDataRequest.addGroup(entryTypeGroup);

    // Add all requested symbols
    for (const auto &symbol : symbols)
    {
      FIX44::MarketDataRequest::NoRelatedSym symbolGroup;
      symbolGroup.set(FIX::Symbol(symbol));
      marketDataRequest.addGroup(symbolGroup);
    }

    FIX::Session::sendToTarget(marketDataRequest, marketDataSessionID);
    return true;
  }
  catch (const std::exception &e)
  {
    std::cerr << "Error sending market data request: " << e.what() << std::endl;
    return false;
  }
}

void Application::onMessage(const FIX44::ExecutionReport &, const FIX::SessionID &) {}

void Application::onMessage(const FIX44::MarketDataSnapshotFullRefresh &message, const FIX::SessionID &)
{
  try
  {
    FIX::Symbol symbol;

    message.get(symbol);

    std::string symbolValue = symbol.getValue();

    // We need variables to store best bid/ask data
    boost::multiprecision::cpp_dec_float_50 bidPrice = 0;
    boost::multiprecision::cpp_dec_float_50 bidQuantity = 0;
    boost::multiprecision::cpp_dec_float_50 askPrice = 0;
    boost::multiprecision::cpp_dec_float_50 askQuantity = 0;

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
      if (entryType == '0')
      { // Bid
        FIX::MDEntryPx entryPrice;
        FIX::MDEntrySize entrySize;

        group.get(entryPrice);
        group.get(entrySize);

        bidPrice = boost::multiprecision::cpp_dec_float_50(entryPrice.getValue());
        bidQuantity = boost::multiprecision::cpp_dec_float_50(entrySize.getValue());
      }
      else if (entryType == '1')
      { // Ask/Offer
        FIX::MDEntryPx entryPrice;
        FIX::MDEntrySize entrySize;

        group.get(entryPrice);
        group.get(entrySize);

        askPrice = boost::multiprecision::cpp_dec_float_50(entryPrice.getValue());
        askQuantity = boost::multiprecision::cpp_dec_float_50(entrySize.getValue());
      }
    }

    // Create price update and add to the queue
    PriceUpdate *update = new PriceUpdate{symbolValue, bidPrice, askPrice, bidQuantity, askQuantity};

    // Push to the queue - if queue is full, this may fail but we don't want to block
    priceUpdateQueue.push(update);
  }
  catch (const std::exception &e)
  {
    std::cerr << "Error processing market data snapshot: " << e.what() << std::endl;
  }
}

void Application::onMessage(const FIX44::MarketDataIncrementalRefresh &message, const FIX::SessionID &)
{
  try
  {
    // Check if we have any MD entries
    FIX::NoMDEntries noMDEntries;
    message.get(noMDEntries);
    int numEntries = noMDEntries.getValue();

    // We may get updates for multiple symbols in a single message
    std::map<std::string, PriceUpdate *> updates;

    for (int i = 1; i <= numEntries; i++)
    {
      FIX44::MarketDataIncrementalRefresh::NoMDEntries group;
      message.getGroup(i, group);

      FIX::MDEntryType entryType;
      group.get(entryType);

      FIX::Symbol symbol;
      group.get(symbol);

      std::string symbolValue = symbol.getValue();

      // Check if we already have an update for this symbol
      if (updates.find(symbolValue) == updates.end())
      {
        // Create a new update
        updates[symbolValue] = new PriceUpdate();
        updates[symbolValue]->symbol = symbolValue;
      }

      // Process update based on entry type (bid or ask)
      FIX::MDUpdateAction action;
      group.get(action);

      // Only process "New" or "Change" actions (0 or 1)
      if (action.getValue() == '0' || action.getValue() == '1')
      {
        FIX::MDEntryPx entryPrice;
        group.get(entryPrice);

        if (group.isSetField(FIX::FIELD::MDEntrySize))
        {
          FIX::MDEntrySize entrySize;
          group.get(entrySize);

          if (entryType == '0')
          { // Bid
            updates[symbolValue]->bidPrice = boost::multiprecision::cpp_dec_float_50(entryPrice.getValue());
            updates[symbolValue]->bidQty = boost::multiprecision::cpp_dec_float_50(entrySize.getValue());
          }
          else if (entryType == '1')
          { // Ask/Offer
            updates[symbolValue]->askPrice = boost::multiprecision::cpp_dec_float_50(entryPrice.getValue());
            updates[symbolValue]->askQty = boost::multiprecision::cpp_dec_float_50(entrySize.getValue());
          }
        }
      }
    }

    // Add all updates to the queue
    for (const auto &[symbol, update] : updates)
    {
      priceUpdateQueue.push(update);
    }
  }
  catch (const std::exception &e)
  {
    std::cerr << "Error processing incremental refresh: " << e.what() << std::endl;
  }
}
