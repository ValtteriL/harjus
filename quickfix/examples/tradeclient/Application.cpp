/* -*- C++ -*- */

/****************************************************************************
** Copyright (c) 2001-2014
**
** This file is part of the QuickFIX FIX Engine
**
** This file may be distributed under the terms of the quickfixengine.org
** license as defined by quickfixengine.org and appearing in the file
** LICENSE included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://www.quickfixengine.org/LICENSE for licensing information.
**
** Contact ask@quickfixengine.org if any conditions of this licensing are
** not clear to you.
**
****************************************************************************/

#ifdef _MSC_VER
#pragma warning(disable : 4503 4355 4786)
#endif

#include "quickfix/config.h"

#include "Application.h"

#include <math.h>
#include "quickfix/Session.h"
#include <iostream>

void Application::onLogon(const FIX::SessionID &sessionID)
{
    std::cout << '\n'
              << "Logon - " << sessionID << '\n';
}

void Application::onLogout(const FIX::SessionID &sessionID)
{
    std::cout << '\n'
              << "Logout - " << sessionID << '\n';
}

void Application::fromApp(const FIX::Message &message, const FIX::SessionID &sessionID)
    EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue, FIX::UnsupportedMessageType)
{
    crack(message, sessionID);
    std::cout << '\n'
              << "IN: " << message << '\n';
}

void Application::toApp(FIX::Message &message, const FIX::SessionID &sessionID) EXCEPT(FIX::DoNotSend)
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

    std::cout << '\n'
              << "OUT: " << message << '\n';
}

void Application::onMessage(const FIX40::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX40::OrderCancelReject &, const FIX::SessionID &) {}
void Application::onMessage(const FIX41::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX41::OrderCancelReject &, const FIX::SessionID &) {}
void Application::onMessage(const FIX42::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX42::OrderCancelReject &, const FIX::SessionID &) {}
void Application::onMessage(const FIX43::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX43::OrderCancelReject &, const FIX::SessionID &) {}
void Application::onMessage(const FIX44::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX44::OrderCancelReject &, const FIX::SessionID &) {}
void Application::onMessage(const FIX50::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX50::OrderCancelReject &, const FIX::SessionID &) {}

void Application::run()
{
    while (true)
    {
        try
        {
            char action = queryAction();

            if (action == '1')
            {
                queryEnterOrder();
            }
            else if (action == '2')
            {
                queryCancelOrder();
            }
            else if (action == '3')
            {
                queryReplaceOrder();
            }
            else if (action == '4')
            {
                queryMarketDataRequest();
            }
            else if (action == '5')
            {
                break;
            }
        }
        catch (std::exception &e)
        {
            std::cout << "Message Not Sent: " << e.what();
        }
    }
}

void Application::queryEnterOrder()
{
    int version = queryVersion();
    std::cout << "\nNewOrderSingle\n";
    FIX::Message order;

    switch (version)
    {
    case 40:
        order = queryNewOrderSingle40();
        break;
    case 41:
        order = queryNewOrderSingle41();
        break;
    case 42:
        order = queryNewOrderSingle42();
        break;
    case 43:
        order = queryNewOrderSingle43();
        break;
    case 44:
        order = queryNewOrderSingle44();
        break;
    case 50:
        order = queryNewOrderSingle50();
        break;
    default:
        std::cerr << "No test for version " << version << '\n';
        break;
    }

    if (queryConfirm("Send order"))
    {
        FIX::Session::sendToTarget(order);
    }
}

void Application::queryCancelOrder()
{
    int version = queryVersion();
    std::cout << "\nOrderCancelRequest\n";
    FIX::Message cancel;

    switch (version)
    {
    case 40:
        cancel = queryOrderCancelRequest40();
        break;
    case 41:
        cancel = queryOrderCancelRequest41();
        break;
    case 42:
        cancel = queryOrderCancelRequest42();
        break;
    case 43:
        cancel = queryOrderCancelRequest43();
        break;
    case 44:
        cancel = queryOrderCancelRequest44();
        break;
    case 50:
        cancel = queryOrderCancelRequest50();
        break;
    default:
        std::cerr << "No test for version " << version << '\n';
        break;
    }

    if (queryConfirm("Send cancel"))
    {
        FIX::Session::sendToTarget(cancel);
    }
}

void Application::queryReplaceOrder()
{
    int version = queryVersion();
    std::cout << "\nCancelReplaceRequest\n";
    FIX::Message replace;

    switch (version)
    {
    case 40:
        replace = queryCancelReplaceRequest40();
        break;
    case 41:
        replace = queryCancelReplaceRequest41();
        break;
    case 42:
        replace = queryCancelReplaceRequest42();
        break;
    case 43:
        replace = queryCancelReplaceRequest43();
        break;
    case 44:
        replace = queryCancelReplaceRequest44();
        break;
    case 50:
        replace = queryCancelReplaceRequest50();
        break;
    default:
        std::cerr << "No test for version " << version << '\n';
        break;
    }

    if (queryConfirm("Send replace"))
    {
        FIX::Session::sendToTarget(replace);
    }
}

void Application::queryMarketDataRequest()
{
    int version = queryVersion();
    std::cout << "\nMarketDataRequest\n";
    FIX::Message md;

    switch (version)
    {
    case 43:
        md = queryMarketDataRequest43();
        break;
    case 44:
        md = queryMarketDataRequest44();
        break;
    case 50:
        md = queryMarketDataRequest50();
        break;
    default:
        std::cerr << "No test for version " << version << '\n';
        break;
    }

    FIX::Session::sendToTarget(md);
}

auto Application::queryNewOrderSingle40() -> FIX40::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX40::NewOrderSingle newOrderSingle(
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySymbol(),
        querySide(),
        queryOrderQty(),
        ordType = queryOrdType());

    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryNewOrderSingle41() -> FIX41::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX41::NewOrderSingle
        newOrderSingle(queryClOrdID(), FIX::HandlInst('1'), querySymbol(), querySide(), ordType = queryOrdType());

    newOrderSingle.set(queryOrderQty());
    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryNewOrderSingle42() -> FIX42::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX42::NewOrderSingle newOrderSingle(
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySymbol(),
        querySide(),
        FIX::TransactTime(),
        ordType = queryOrdType());

    newOrderSingle.set(queryOrderQty());
    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryNewOrderSingle43() -> FIX43::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX43::NewOrderSingle
        newOrderSingle(queryClOrdID(), FIX::HandlInst('1'), querySide(), FIX::TransactTime(), ordType = queryOrdType());

    newOrderSingle.set(querySymbol());
    newOrderSingle.set(queryOrderQty());
    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryNewOrderSingle44() -> FIX44::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX44::NewOrderSingle newOrderSingle(queryClOrdID(), querySide(), FIX::TransactTime(), ordType = queryOrdType());

    newOrderSingle.set(FIX::HandlInst('1'));
    newOrderSingle.set(querySymbol());
    newOrderSingle.set(queryOrderQty());
    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryNewOrderSingle50() -> FIX50::NewOrderSingle
{
    FIX::OrdType ordType;

    FIX50::NewOrderSingle newOrderSingle(queryClOrdID(), querySide(), FIX::TransactTime(), ordType = queryOrdType());

    newOrderSingle.set(FIX::HandlInst('1'));
    newOrderSingle.set(querySymbol());
    newOrderSingle.set(queryOrderQty());
    newOrderSingle.set(queryTimeInForce());
    if (ordType == FIX::OrdType_LIMIT || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryPrice());
    }
    if (ordType == FIX::OrdType_STOP || ordType == FIX::OrdType_STOP_LIMIT)
    {
        newOrderSingle.set(queryStopPx());
    }

    queryHeader(newOrderSingle.getHeader());
    return newOrderSingle;
}

auto Application::queryOrderCancelRequest40() -> FIX40::OrderCancelRequest
{
    FIX40::OrderCancelRequest orderCancelRequest(
        queryOrigClOrdID(),
        queryClOrdID(),
        FIX::CxlType('F'),
        querySymbol(),
        querySide(),
        queryOrderQty());

    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryOrderCancelRequest41() -> FIX41::OrderCancelRequest
{
    FIX41::OrderCancelRequest orderCancelRequest(queryOrigClOrdID(), queryClOrdID(), querySymbol(), querySide());

    orderCancelRequest.set(queryOrderQty());
    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryOrderCancelRequest42() -> FIX42::OrderCancelRequest
{
    FIX42::OrderCancelRequest
        orderCancelRequest(queryOrigClOrdID(), queryClOrdID(), querySymbol(), querySide(), FIX::TransactTime());

    orderCancelRequest.set(queryOrderQty());
    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryOrderCancelRequest43() -> FIX43::OrderCancelRequest
{
    FIX43::OrderCancelRequest orderCancelRequest(queryOrigClOrdID(), queryClOrdID(), querySide(), FIX::TransactTime());

    orderCancelRequest.set(querySymbol());
    orderCancelRequest.set(queryOrderQty());
    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryOrderCancelRequest44() -> FIX44::OrderCancelRequest
{
    FIX44::OrderCancelRequest orderCancelRequest(queryOrigClOrdID(), queryClOrdID(), querySide(), FIX::TransactTime());

    orderCancelRequest.set(querySymbol());
    orderCancelRequest.set(queryOrderQty());
    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryOrderCancelRequest50() -> FIX50::OrderCancelRequest
{
    FIX50::OrderCancelRequest orderCancelRequest(queryOrigClOrdID(), queryClOrdID(), querySide(), FIX::TransactTime());

    orderCancelRequest.set(querySymbol());
    orderCancelRequest.set(queryOrderQty());
    queryHeader(orderCancelRequest.getHeader());
    return orderCancelRequest;
}

auto Application::queryCancelReplaceRequest40() -> FIX40::OrderCancelReplaceRequest
{
    FIX40::OrderCancelReplaceRequest cancelReplaceRequest(
        queryOrigClOrdID(),
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySymbol(),
        querySide(),
        queryOrderQty(),
        queryOrdType());

    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryCancelReplaceRequest41() -> FIX41::OrderCancelReplaceRequest
{
    FIX41::OrderCancelReplaceRequest cancelReplaceRequest(
        queryOrigClOrdID(),
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySymbol(),
        querySide(),
        queryOrdType());

    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryCancelReplaceRequest42() -> FIX42::OrderCancelReplaceRequest
{
    FIX42::OrderCancelReplaceRequest cancelReplaceRequest(
        queryOrigClOrdID(),
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySymbol(),
        querySide(),
        FIX::TransactTime(),
        queryOrdType());

    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryCancelReplaceRequest43() -> FIX43::OrderCancelReplaceRequest
{
    FIX43::OrderCancelReplaceRequest cancelReplaceRequest(
        queryOrigClOrdID(),
        queryClOrdID(),
        FIX::HandlInst('1'),
        querySide(),
        FIX::TransactTime(),
        queryOrdType());

    cancelReplaceRequest.set(querySymbol());
    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryCancelReplaceRequest44() -> FIX44::OrderCancelReplaceRequest
{
    FIX44::OrderCancelReplaceRequest
        cancelReplaceRequest(queryOrigClOrdID(), queryClOrdID(), querySide(), FIX::TransactTime(), queryOrdType());

    cancelReplaceRequest.set(FIX::HandlInst('1'));
    cancelReplaceRequest.set(querySymbol());
    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryCancelReplaceRequest50() -> FIX50::OrderCancelReplaceRequest
{
    FIX50::OrderCancelReplaceRequest
        cancelReplaceRequest(queryOrigClOrdID(), queryClOrdID(), querySide(), FIX::TransactTime(), queryOrdType());

    cancelReplaceRequest.set(FIX::HandlInst('1'));
    cancelReplaceRequest.set(querySymbol());
    if (queryConfirm("New price"))
    {
        cancelReplaceRequest.set(queryPrice());
    }
    if (queryConfirm("New quantity"))
    {
        cancelReplaceRequest.set(queryOrderQty());
    }

    queryHeader(cancelReplaceRequest.getHeader());
    return cancelReplaceRequest;
}

auto Application::queryMarketDataRequest43() -> FIX43::MarketDataRequest
{
    FIX::MDReqID mdReqID("MARKETDATAID");
    FIX::SubscriptionRequestType subType(FIX::SubscriptionRequestType_SNAPSHOT);
    FIX::MarketDepth marketDepth(0);

    FIX43::MarketDataRequest::NoMDEntryTypes marketDataEntryGroup;
    FIX::MDEntryType mdEntryType(FIX::MDEntryType_BID);
    marketDataEntryGroup.set(mdEntryType);

    FIX43::MarketDataRequest::NoRelatedSym symbolGroup;
    FIX::Symbol symbol("LNUX");
    symbolGroup.set(symbol);

    FIX43::MarketDataRequest message(mdReqID, subType, marketDepth);
    message.addGroup(marketDataEntryGroup);
    message.addGroup(symbolGroup);

    queryHeader(message.getHeader());

    std::cout << message.toXML() << '\n';
    std::cout << message.toString() << '\n';

    return message;
}

auto Application::queryMarketDataRequest44() -> FIX44::MarketDataRequest
{
    FIX::MDReqID mdReqID("MARKETDATAID");
    FIX::SubscriptionRequestType subType(FIX::SubscriptionRequestType_SNAPSHOT);
    FIX::MarketDepth marketDepth(0);

    FIX44::MarketDataRequest::NoMDEntryTypes marketDataEntryGroup;
    FIX::MDEntryType mdEntryType(FIX::MDEntryType_BID);
    marketDataEntryGroup.set(mdEntryType);

    FIX44::MarketDataRequest::NoRelatedSym symbolGroup;
    FIX::Symbol symbol("LNUX");
    symbolGroup.set(symbol);

    FIX44::MarketDataRequest message(mdReqID, subType, marketDepth);
    message.addGroup(marketDataEntryGroup);
    message.addGroup(symbolGroup);

    queryHeader(message.getHeader());

    std::cout << message.toXML() << '\n';
    std::cout << message.toString() << '\n';

    return message;
}

auto Application::queryMarketDataRequest50() -> FIX50::MarketDataRequest
{
    FIX::MDReqID mdReqID("MARKETDATAID");
    FIX::SubscriptionRequestType subType(FIX::SubscriptionRequestType_SNAPSHOT);
    FIX::MarketDepth marketDepth(0);

    FIX50::MarketDataRequest::NoMDEntryTypes marketDataEntryGroup;
    FIX::MDEntryType mdEntryType(FIX::MDEntryType_BID);
    marketDataEntryGroup.set(mdEntryType);

    FIX50::MarketDataRequest::NoRelatedSym symbolGroup;
    FIX::Symbol symbol("LNUX");
    symbolGroup.set(symbol);

    FIX50::MarketDataRequest message(mdReqID, subType, marketDepth);
    message.addGroup(marketDataEntryGroup);
    message.addGroup(symbolGroup);

    queryHeader(message.getHeader());

    std::cout << message.toXML() << '\n';
    std::cout << message.toString() << '\n';

    return message;
}

void Application::queryHeader(FIX::Header &header)
{
    header.setField(querySenderCompID());
    header.setField(queryTargetCompID());

    if (queryConfirm("Use a TargetSubID"))
    {
        header.setField(queryTargetSubID());
    }
}

auto Application::queryAction() -> char
{
    char value = 0;
    std::cout << '\n'
              << "1) Enter Order" << '\n'
              << "2) Cancel Order" << '\n'
              << "3) Replace Order" << '\n'
              << "4) Market data test" << '\n'
              << "5) Quit" << '\n'
              << "Action: ";
    std::cin >> value;
    switch (value)
    {
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
        break;
    default:
        throw std::exception();
    }
    return value;
}

auto Application::queryVersion() -> int
{
    char value = 0;
    std::cout << '\n'
              << "1) FIX.4.0" << '\n'
              << "2) FIX.4.1" << '\n'
              << "3) FIX.4.2" << '\n'
              << "4) FIX.4.3" << '\n'
              << "5) FIX.4.4" << '\n'
              << "6) FIXT.1.1 (FIX.5.0)" << '\n'
              << "BeginString: ";
    std::cin >> value;
    switch (value)
    {
    case '1':
        return 40;
    case '2':
        return 41;
    case '3':
        return 42;
    case '4':
        return 43;
    case '5':
        return 44;
    case '6':
        return 50;
    default:
        throw std::exception();
    }
}

auto Application::queryConfirm(const std::string &query) -> bool
{
    std::string value;
    std::cout << '\n'
              << query << "?: ";
    std::cin >> value;
    return toupper(*value.c_str()) == 'Y';
}

auto Application::querySenderCompID() -> FIX::SenderCompID
{
    std::string value;
    std::cout << '\n'
              << "SenderCompID: ";
    std::cin >> value;
    return FIX::SenderCompID(value);
}

auto Application::queryTargetCompID() -> FIX::TargetCompID
{
    std::string value;
    std::cout << '\n'
              << "TargetCompID: ";
    std::cin >> value;
    return FIX::TargetCompID(value);
}

auto Application::queryTargetSubID() -> FIX::TargetSubID
{
    std::string value;
    std::cout << '\n'
              << "TargetSubID: ";
    std::cin >> value;
    return FIX::TargetSubID(value);
}

auto Application::queryClOrdID() -> FIX::ClOrdID
{
    std::string value;
    std::cout << '\n'
              << "ClOrdID: ";
    std::cin >> value;
    return FIX::ClOrdID(value);
}

auto Application::queryOrigClOrdID() -> FIX::OrigClOrdID
{
    std::string value;
    std::cout << '\n'
              << "OrigClOrdID: ";
    std::cin >> value;
    return FIX::OrigClOrdID(value);
}

auto Application::querySymbol() -> FIX::Symbol
{
    std::string value;
    std::cout << '\n'
              << "Symbol: ";
    std::cin >> value;
    return FIX::Symbol(value);
}

auto Application::querySide() -> FIX::Side
{
    char value = 0;
    std::cout << '\n'
              << "1) Buy" << '\n'
              << "2) Sell" << '\n'
              << "3) Sell Short" << '\n'
              << "4) Sell Short Exempt" << '\n'
              << "5) Cross" << '\n'
              << "6) Cross Short" << '\n'
              << "7) Cross Short Exempt" << '\n'
              << "Side: ";

    std::cin >> value;
    switch (value)
    {
    case '1':
        return FIX::Side(FIX::Side_BUY);
    case '2':
        return FIX::Side(FIX::Side_SELL);
    case '3':
        return FIX::Side(FIX::Side_SELL_SHORT);
    case '4':
        return FIX::Side(FIX::Side_SELL_SHORT_EXEMPT);
    case '5':
        return FIX::Side(FIX::Side_CROSS);
    case '6':
        return FIX::Side(FIX::Side_CROSS_SHORT);
    case '7':
        return FIX::Side('A');
    default:
        throw std::exception();
    }
}

auto Application::queryOrderQty() -> FIX::OrderQty
{
    long value = 0;
    std::cout << '\n'
              << "OrderQty: ";
    std::cin >> value;
    return FIX::OrderQty(value);
}

auto Application::queryOrdType() -> FIX::OrdType
{
    char value = 0;
    std::cout << '\n'
              << "1) Market" << '\n'
              << "2) Limit" << '\n'
              << "3) Stop" << '\n'
              << "4) Stop Limit" << '\n'
              << "OrdType: ";

    std::cin >> value;
    switch (value)
    {
    case '1':
        return FIX::OrdType(FIX::OrdType_MARKET);
    case '2':
        return FIX::OrdType(FIX::OrdType_LIMIT);
    case '3':
        return FIX::OrdType(FIX::OrdType_STOP);
    case '4':
        return FIX::OrdType(FIX::OrdType_STOP_LIMIT);
    default:
        throw std::exception();
    }
}

auto Application::queryPrice() -> FIX::Price
{
    double value = NAN;
    std::cout << '\n'
              << "Price: ";
    std::cin >> value;
    return FIX::Price(value);
}

auto Application::queryStopPx() -> FIX::StopPx
{
    double value = NAN;
    std::cout << '\n'
              << "StopPx: ";
    std::cin >> value;
    return FIX::StopPx(value);
}

auto Application::queryTimeInForce() -> FIX::TimeInForce
{
    char value = 0;
    std::cout << '\n'
              << "1) Day" << '\n'
              << "2) IOC" << '\n'
              << "3) OPG" << '\n'
              << "4) GTC" << '\n'
              << "5) GTX" << '\n'
              << "TimeInForce: ";

    std::cin >> value;
    switch (value)
    {
    case '1':
        return FIX::TimeInForce(FIX::TimeInForce_DAY);
    case '2':
        return FIX::TimeInForce(FIX::TimeInForce_IMMEDIATE_OR_CANCEL);
    case '3':
        return FIX::TimeInForce(FIX::TimeInForce_AT_THE_OPENING);
    case '4':
        return FIX::TimeInForce(FIX::TimeInForce_GOOD_TILL_CANCEL);
    case '5':
        return FIX::TimeInForce(FIX::TimeInForce_GOOD_TILL_CROSSING);
    default:
        throw std::exception();
    }
}
