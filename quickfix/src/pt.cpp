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

#include "FixFields.h"
#ifdef _MSC_VER
#pragma warning(disable : 4503 4355 4786)
#include "stdafx.h"
#else
#include "config.h"
#endif

#include "Application.h"
#include "DataDictionary.h"
#include "FieldConvertors.h"
#include "FileStore.h"
#include "Parser.h"
#include "Session.h"
#include "SessionID.h"
#include "SocketAcceptor.h"
#include "SocketInitiator.h"
#include "ThreadedSocketAcceptor.h"
#include "ThreadedSocketInitiator.h"
#include "Utility.h"
#include "Values.h"
#include "fix42/Heartbeat.h"
#include "fix42/NewOrderSingle.h"
#include "fix42/QuoteRequest.h"
#include "getopt-repl.h"
#include <iostream>
#include <memory>

auto testIntegerToString(int) -> long;
auto testStringToInteger(int) -> long;
auto testDoubleToString(int) -> long;
auto testStringToDouble(int) -> long;
auto testCreateHeartbeat(int) -> long;
auto testIdentifyType(int) -> long;
auto testSerializeHeartbeat(int) -> long;
auto testDeserializeHeartbeat(int) -> long;
auto testDeserializeAndValidateHeartbeat(int) -> long;
auto testCreateNewOrderSingle(int) -> long;
auto testSerializeNewOrderSingle(int) -> long;
auto testDeserializeNewOrderSingle(int) -> long;
auto testDeserializeAndValidateNewOrderSingle(int) -> long;
auto testCreateQuoteRequest(int) -> long;
auto testReadFromQuoteRequest(int) -> long;
auto testSerializeQuoteRequest(int) -> long;
auto testDeserializeQuoteRequest(int) -> long;
auto testDeserializeAndValidateQuoteRequest(int) -> long;
auto testFileStoreNewOrderSingle(int) -> long;
auto testValidateNewOrderSingle(int) -> long;
auto testValidateDictNewOrderSingle(int) -> long;
auto testValidateQuoteRequest(int) -> long;
auto testValidateDictQuoteRequest(int) -> long;
auto testSendOnSocket(int, short) -> long;
auto testSendOnThreadedSocket(int, short) -> long;
void report(long, int);

#ifndef _MSC_VER
#include <sys/time.h>
auto GetTickCount() -> long
{
    timeval tv{};
    gettimeofday(&tv, nullptr);
    long microsec = tv.tv_sec * 1e6;
    microsec += (long)tv.tv_usec;

    return (long)microsec;
}
#endif

std::unique_ptr<FIX::DataDictionary> s_dataDictionary;
const bool VALIDATE = true;
const bool DONT_VALIDATE = false;

auto main(int argc, char **argv) -> int
{
    int count = 0;
    short port = 0;

    int opt = 0;
    while ((opt = getopt(argc, argv, "+p:+c:")) != -1)
    {
        switch (opt)
        {
        case 'p':
            port = (short)atol(optarg);
            break;
        case 'c':
            count = atoi(optarg);
            break;
        default:
            std::cout << "usage: " << argv[0] << " -p port -c count" << '\n';
            return EXIT_FAILURE;
        }
    }

    try
    {
        s_dataDictionary = std::make_unique<FIX::DataDictionary>("../spec/FIX42.xml");

        std::cout << "Converting integers to strings: ";
        report(testIntegerToString(count), count);

        std::cout << "Converting strings to integers: ";
        report(testStringToInteger(count), count);

        std::cout << "Converting doubles to strings: ";
        report(testDoubleToString(count), count);

        std::cout << "Converting strings to doubles: ";
        report(testStringToDouble(count), count);

        std::cout << "Creating Heartbeat messages: ";
        report(testCreateHeartbeat(count), count);

        std::cout << "Identifying message types: ";
        report(testIdentifyType(count), count);

        std::cout << "Serializing Heartbeat messages: ";
        report(testSerializeHeartbeat(count), count);

        std::cout << "Deserializing Heartbeat messages: ";
        report(testDeserializeHeartbeat(count), count);

        std::cout << "Deserializing and validating Heartbeat messages: ";
        report(testDeserializeAndValidateHeartbeat(count), count);

        std::cout << "Creating NewOrderSingle messages: ";
        report(testCreateNewOrderSingle(count), count);

        std::cout << "Serializing NewOrderSingle messages: ";
        report(testSerializeNewOrderSingle(count), count);

        std::cout << "Deserializing NewOrderSingle messages: ";
        report(testDeserializeNewOrderSingle(count), count);

        std::cout << "Deserializing and validating NewOrderSingle messages: ";
        report(testDeserializeAndValidateNewOrderSingle(count), count);

        std::cout << "Creating QuoteRequest messages: ";
        report(testCreateQuoteRequest(count), count);

        std::cout << "Serializing QuoteRequest messages: ";
        report(testSerializeQuoteRequest(count), count);

        std::cout << "Deserializing QuoteRequest messages: ";
        report(testDeserializeQuoteRequest(count), count);

        std::cout << "Deserializing and validating QuoteRequest messages: ";
        report(testDeserializeAndValidateQuoteRequest(count), count);

        std::cout << "Reading fields from QuoteRequest message: ";
        report(testReadFromQuoteRequest(count), count);

        std::cout << "Storing NewOrderSingle messages: ";
        report(testFileStoreNewOrderSingle(count), count);

        std::cout << "Validating NewOrderSingle messages with no data dictionary: ";
        report(testValidateNewOrderSingle(count), count);

        std::cout << "Validating NewOrderSingle messages with data dictionary: ";
        report(testValidateDictNewOrderSingle(count), count);

        std::cout << "Validating QuoteRequest messages with no data dictionary: ";
        report(testValidateQuoteRequest(count), count);

        std::cout << "Validating QuoteRequest messages with data dictionary: ";
        report(testValidateDictQuoteRequest(count), count);

        std::cout << "Sending/Receiving NewOrderSingle/ExecutionReports on Socket";
        report(testSendOnSocket(count, port), count);

        std::cout << "Sending/Receiving NewOrderSingle/ExecutionReports on ThreadedSocket";
        report(testSendOnThreadedSocket(count, port), count);
    }
    catch (std::exception const &e)
    {
        std::cerr << e.what() << '\n';
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

void report(long total_micros, int count)
{
    double total_seconds = static_cast<double>(total_micros) / 1e6;
    double num_per_second = count / total_seconds;
    double micros_per = static_cast<double>(total_micros) / count;
    std::cout << '\n'
              << "    num: " << count << ", total_seconds: " << total_seconds << ", num_per_second: " << num_per_second
              << ", micros_per: " << micros_per << '\n';
}

auto testIntegerToString(int count) -> long
{
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::IntConvertor::convert(1234);
    }
    return GetTickCount() - start;
}

auto testStringToInteger(int count) -> long
{
    std::string value("1234");
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::IntConvertor::convert(value);
    }
    return GetTickCount() - start;
}

auto testDoubleToString(int count) -> long
{
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::DoubleConvertor::convert(123.45);
    }
    return GetTickCount() - start;
}

auto testStringToDouble(int count) -> long
{
    std::string value("123.45");
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::DoubleConvertor::convert(value);
    }
    return GetTickCount() - start;
}

auto testCreateHeartbeat(int count) -> long
{
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX42::Heartbeat();
    }

    return GetTickCount() - start;
}

auto testIdentifyType(int count) -> long
{
    FIX42::Heartbeat message;
    std::string messageString = message.toString();

    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::identifyType(messageString);
    }

    return GetTickCount() - start;
}

auto testSerializeHeartbeat(int count) -> long
{
    FIX42::Heartbeat message;
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.toString();
    }
    return GetTickCount() - start;
}

auto testDeserializeHeartbeat(int count) -> long
{
    FIX42::Heartbeat message;
    std::string string = message.toString();
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.setString(string, DONT_VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testDeserializeAndValidateHeartbeat(int count) -> long
{
    FIX42::Heartbeat message;
    std::string string = message.toString();
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.setString(string, VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testCreateNewOrderSingle(int count) -> long
{
    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::ClOrdID clOrdID("ORDERID");
        FIX::HandlInst handlInst('1');
        FIX::Symbol symbol("LNUX");
        FIX::Side side(FIX::Side_BUY);
        FIX::TransactTime transactTime = FIX::TransactTime::now();
        FIX::OrdType ordType(FIX::OrdType_MARKET);
        FIX42::NewOrderSingle(clOrdID, handlInst, symbol, side, transactTime, ordType);
    }

    return GetTickCount() - start;
}

auto testSerializeNewOrderSingle(int count) -> long
{
    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);

    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.toString();
    }
    return GetTickCount() - start;
}

auto testDeserializeNewOrderSingle(int count) -> long
{
    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);
    std::string string = message.toString();

    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.setString(string, DONT_VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testDeserializeAndValidateNewOrderSingle(int count) -> long
{
    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);
    std::string string = message.toString();

    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        message.setString(string, VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testCreateQuoteRequest(int count) -> long
{
    count = count - 1;

    long start = GetTickCount();
    FIX::Symbol symbol;
    FIX::MaturityMonthYear maturityMonthYear;
    FIX::PutOrCall putOrCall;
    FIX::StrikePrice strikePrice;
    FIX::Side side;
    FIX::OrderQty orderQty;
    FIX::Currency currency;
    FIX::OrdType ordType;

    for (int i = 0; i <= count; ++i)
    {
        FIX42::QuoteRequest massQuote(FIX::QuoteReqID("1"));
        FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

        for (int j = 1; j <= 10; ++j)
        {
            symbol.setValue("IBM");
            maturityMonthYear.setValue("022003");
            putOrCall.setValue(FIX::PutOrCall_PUT);
            strikePrice.setValue(120);
            side.setValue(FIX::Side_BUY);
            orderQty.setValue(100);
            currency.setValue("USD");
            ordType.setValue(FIX::OrdType_MARKET);
            noRelatedSym.set(symbol);
            noRelatedSym.set(maturityMonthYear);
            noRelatedSym.set(putOrCall);
            noRelatedSym.set(strikePrice);
            noRelatedSym.set(side);
            noRelatedSym.set(orderQty);
            noRelatedSym.set(currency);
            noRelatedSym.set(ordType);
            massQuote.addGroup(noRelatedSym);
            noRelatedSym.clear();
        }
    }

    return GetTickCount() - start;
}

auto testSerializeQuoteRequest(int count) -> long
{
    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

    for (int i = 1; i <= 10; ++i)
    {
        noRelatedSym.set(FIX::Symbol("IBM"));
        noRelatedSym.set(FIX::MaturityMonthYear());
        noRelatedSym.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        noRelatedSym.set(FIX::StrikePrice(120));
        noRelatedSym.set(FIX::Side(FIX::Side_BUY));
        noRelatedSym.set(FIX::OrderQty(100));
        noRelatedSym.set(FIX::Currency("USD"));
        noRelatedSym.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(noRelatedSym);
    }

    count = count - 1;

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        message.toString();
    }
    return GetTickCount() - start;
}

auto testDeserializeQuoteRequest(int count) -> long
{
    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

    for (int i = 1; i <= 10; ++i)
    {
        noRelatedSym.set(FIX::Symbol("IBM"));
        noRelatedSym.set(FIX::MaturityMonthYear());
        noRelatedSym.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        noRelatedSym.set(FIX::StrikePrice(120));
        noRelatedSym.set(FIX::Side(FIX::Side_BUY));
        noRelatedSym.set(FIX::OrderQty(100));
        noRelatedSym.set(FIX::Currency("USD"));
        noRelatedSym.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(noRelatedSym);
    }
    std::string string = message.toString();

    count = count - 1;

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        message.setString(string, DONT_VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testDeserializeAndValidateQuoteRequest(int count) -> long
{
    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

    for (int i = 1; i <= 10; ++i)
    {
        noRelatedSym.set(FIX::Symbol("IBM"));
        noRelatedSym.set(FIX::MaturityMonthYear());
        noRelatedSym.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        noRelatedSym.set(FIX::StrikePrice(120));
        noRelatedSym.set(FIX::Side(FIX::Side_BUY));
        noRelatedSym.set(FIX::OrderQty(100));
        noRelatedSym.set(FIX::Currency("USD"));
        noRelatedSym.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(noRelatedSym);
    }
    std::string string = message.toString();

    count = count - 1;

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        message.setString(string, VALIDATE, s_dataDictionary.get());
    }
    return GetTickCount() - start;
}

auto testReadFromQuoteRequest(int count) -> long
{
    count = count - 1;

    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym group;

    for (int i = 1; i <= 10; ++i)
    {
        group.set(FIX::Symbol("IBM"));
        group.set(FIX::MaturityMonthYear());
        group.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        group.set(FIX::StrikePrice(120));
        group.set(FIX::Side(FIX::Side_BUY));
        group.set(FIX::OrderQty(100));
        group.set(FIX::Currency("USD"));
        group.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(group);
    }
    group.clear();

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        FIX::QuoteReqID quoteReqID;
        FIX::Symbol symbol;
        FIX::MaturityMonthYear maturityMonthYear;
        FIX::PutOrCall putOrCall;
        FIX::StrikePrice strikePrice;
        FIX::Side side;
        FIX::OrderQty orderQty;
        FIX::Currency currency;
        FIX::OrdType ordType;

        FIX::NoRelatedSym noRelatedSym;
        message.get(noRelatedSym);
        int end = noRelatedSym;
        for (int k = 1; k <= end; ++k)
        {
            message.getGroup(k, group);
            group.get(symbol);
            group.get(maturityMonthYear);
            group.get(putOrCall);
            group.get(strikePrice);
            group.get(side);
            group.get(orderQty);
            group.get(currency);
            group.get(ordType);
            maturityMonthYear.getValue();
            putOrCall.getValue();
            strikePrice.getValue();
            side.getValue();
            orderQty.getValue();
            currency.getValue();
            ordType.getValue();
        }
    }

    return GetTickCount() - start;
}

auto testFileStoreNewOrderSingle(int count) -> long
{
    FIX::BeginString beginString(FIX::BeginString_FIX42);
    FIX::SenderCompID senderCompID("SENDER");
    FIX::TargetCompID targetCompID("TARGET");
    FIX::SessionID id(beginString, senderCompID, targetCompID);

    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);
    message.getHeader().set(FIX::MsgSeqNum(1));
    std::string messageString = message.toString();

    FIX::FileStore store(FIX::UtcTimeStamp::now(), "store", id);
    store.reset(FIX::UtcTimeStamp::now());
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        store.set(++i, messageString);
    }
    long end = GetTickCount();
    store.reset(FIX::UtcTimeStamp::now());
    return end - start;
}

auto testValidateNewOrderSingle(int count) -> long
{
    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);
    message.getHeader().set(FIX::SenderCompID("SENDER"));
    message.getHeader().set(FIX::TargetCompID("TARGET"));
    message.getHeader().set(FIX::MsgSeqNum(1));
    message.getHeader().set(FIX::SendingTime::now());
    message.getHeader().set(FIX::BodyLength(message.calculateLength()));
    message.getTrailer().set(FIX::CheckSum(message.checkSum()));

    FIX::DataDictionary dataDictionary;
    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        dataDictionary.validate(message);
    }
    return GetTickCount() - start;
}

auto testValidateDictNewOrderSingle(int count) -> long
{
    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);
    message.getHeader().set(FIX::SenderCompID("SENDER"));
    message.getHeader().set(FIX::TargetCompID("TARGET"));
    message.getHeader().set(FIX::MsgSeqNum(1));
    message.getHeader().set(FIX::SendingTime::now());
    message.getHeader().set(FIX::BodyLength(message.calculateLength()));
    message.getTrailer().set(FIX::CheckSum(message.checkSum()));

    count = count - 1;

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        s_dataDictionary->validate(message);
    }
    return GetTickCount() - start;
}

auto testValidateQuoteRequest(int count) -> long
{
    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

    for (int i = 1; i <= 10; ++i)
    {
        noRelatedSym.set(FIX::Symbol("IBM"));
        noRelatedSym.set(FIX::MaturityMonthYear());
        noRelatedSym.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        noRelatedSym.set(FIX::StrikePrice(120));
        noRelatedSym.set(FIX::Side(FIX::Side_BUY));
        noRelatedSym.set(FIX::OrderQty(100));
        noRelatedSym.set(FIX::Currency("USD"));
        noRelatedSym.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(noRelatedSym);
    }

    message.getHeader().set(FIX::SenderCompID("SENDER"));
    message.getHeader().set(FIX::TargetCompID("TARGET"));
    message.getHeader().set(FIX::MsgSeqNum(1));
    message.getHeader().set(FIX::SendingTime::now());
    message.getHeader().set(FIX::BodyLength(message.calculateLength()));
    message.getTrailer().set(FIX::CheckSum(message.checkSum()));

    FIX::DataDictionary dataDictionary;
    count = count - 1;

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        dataDictionary.validate(message);
    }
    return GetTickCount() - start;
}

auto testValidateDictQuoteRequest(int count) -> long
{
    FIX42::QuoteRequest message(FIX::QuoteReqID("1"));
    FIX42::QuoteRequest::NoRelatedSym noRelatedSym;

    for (int i = 1; i <= 10; ++i)
    {
        noRelatedSym.set(FIX::Symbol("IBM"));
        noRelatedSym.set(FIX::MaturityMonthYear());
        noRelatedSym.set(FIX::PutOrCall(FIX::PutOrCall_PUT));
        noRelatedSym.set(FIX::StrikePrice(120));
        noRelatedSym.set(FIX::Side(FIX::Side_BUY));
        noRelatedSym.set(FIX::OrderQty(100));
        noRelatedSym.set(FIX::Currency("USD"));
        noRelatedSym.set(FIX::OrdType(FIX::OrdType_MARKET));
        message.addGroup(noRelatedSym);
    }

    message.getHeader().set(FIX::SenderCompID("SENDER"));
    message.getHeader().set(FIX::TargetCompID("TARGET"));
    message.getHeader().set(FIX::MsgSeqNum(1));
    message.getHeader().set(FIX::SendingTime::now());
    message.getHeader().set(FIX::BodyLength(message.calculateLength()));
    message.getTrailer().set(FIX::CheckSum(message.checkSum()));

    count = count - 1;

    long start = GetTickCount();
    for (int j = 0; j <= count; ++j)
    {
        s_dataDictionary->validate(message);
    }
    return GetTickCount() - start;
}

class TestApplication : public FIX::NullApplication
{
public:
    TestApplication()
         {}

    void fromApp(const FIX::Message &m, const FIX::SessionID &)
        EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat, FIX::IncorrectTagValue, FIX::UnsupportedMessageType) override
    {
        m_count++;
    }

    auto getCount() -> int { return m_count; }

private:
    int m_count{0};
};

auto testSendOnSocket(int count, short port) -> long
{
    std::stringstream stream;
    stream << "[DEFAULT]" << '\n'
           << "SocketConnectHost=localhost" << '\n'
           << "SocketConnectPort=" << (unsigned short)port << '\n'
           << "SocketAcceptPort=" << (unsigned short)port << '\n'
           << "SocketReuseAddress=Y" << '\n'
           << "StartTime=00:00:00" << '\n'
           << "EndTime=00:00:00" << '\n'
           << "UseDataDictionary=N" << '\n'
           << "BeginString=FIX.4.2" << '\n'
           << "PersistMessages=N" << '\n'
           << "[SESSION]" << '\n'
           << "ConnectionType=acceptor" << '\n'
           << "SenderCompID=SERVER" << '\n'
           << "TargetCompID=CLIENT" << '\n'
           << "[SESSION]" << '\n'
           << "ConnectionType=initiator" << '\n'
           << "SenderCompID=CLIENT" << '\n'
           << "TargetCompID=SERVER" << '\n'
           << "HeartBtInt=30" << '\n';

    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);

    FIX::SessionID sessionID("FIX.4.2", "CLIENT", "SERVER");

    TestApplication application;
    FIX::MemoryStoreFactory factory;
    FIX::SessionSettings settings(stream);
    FIX::ScreenLogFactory logFactory(settings);

    FIX::SocketAcceptor acceptor(application, factory, settings);
    acceptor.start();

    FIX::SocketInitiator initiator(application, factory, settings);
    initiator.start();

    FIX::process_sleep(1);

    long start = GetTickCount();

    for (int i = 0; i <= count; ++i)
    {
        FIX::Session::sendToTarget(message, sessionID);
    }

    while (application.getCount() < count)
    {
        FIX::process_sleep(0.1);
    }

    long ticks = GetTickCount() - start;

    initiator.stop();
    acceptor.stop();

    return ticks;
}

auto testSendOnThreadedSocket(int count, short port) -> long
{
    std::stringstream stream;
    stream << "[DEFAULT]" << '\n'
           << "SocketConnectHost=localhost" << '\n'
           << "SocketConnectPort=" << (unsigned short)port << '\n'
           << "SocketAcceptPort=" << (unsigned short)port << '\n'
           << "SocketReuseAddress=Y" << '\n'
           << "StartTime=00:00:00" << '\n'
           << "EndTime=00:00:00" << '\n'
           << "UseDataDictionary=N" << '\n'
           << "BeginString=FIX.4.2" << '\n'
           << "PersistMessages=N" << '\n'
           << "[SESSION]" << '\n'
           << "ConnectionType=acceptor" << '\n'
           << "SenderCompID=SERVER" << '\n'
           << "TargetCompID=CLIENT" << '\n'
           << "[SESSION]" << '\n'
           << "ConnectionType=initiator" << '\n'
           << "SenderCompID=CLIENT" << '\n'
           << "TargetCompID=SERVER" << '\n'
           << "HeartBtInt=30" << '\n';

    FIX::ClOrdID clOrdID("ORDERID");
    FIX::HandlInst handlInst('1');
    FIX::Symbol symbol("LNUX");
    FIX::Side side(FIX::Side_BUY);
    FIX::TransactTime transactTime = FIX::TransactTime::now();
    FIX::OrdType ordType(FIX::OrdType_MARKET);
    FIX42::NewOrderSingle message(clOrdID, handlInst, symbol, side, transactTime, ordType);

    FIX::SessionID sessionID("FIX.4.2", "CLIENT", "SERVER");

    TestApplication application;
    FIX::MemoryStoreFactory factory;
    FIX::SessionSettings settings(stream);

    FIX::ThreadedSocketAcceptor acceptor(application, factory, settings);
    acceptor.start();

    FIX::ThreadedSocketInitiator initiator(application, factory, settings);
    initiator.start();

    FIX::process_sleep(1);

    long start = GetTickCount();
    for (int i = 0; i <= count; ++i)
    {
        FIX::Session::sendToTarget(message, sessionID);
    }

    while (application.getCount() < count)
    {
        FIX::process_sleep(0.1);
    }

    long ticks = GetTickCount() - start;

    initiator.stop();
    acceptor.stop();

    return ticks;
}
