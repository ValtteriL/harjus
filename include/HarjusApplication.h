#pragma once

/**
 * @file HarjusApplication.h
 * @brief Header file for the FIX Application class.
 * @details This file contains the definition of the Application class, which
 * implements the FIX::Application interface and handles FIX messages.
 */

#include "ExecutionReport.h"
#include "IApplication.h"
#include "IConfiguration.h"
#include "PriceUpdate.h"

#include <Field.h>

#include <Application.h>
#include <MessageCracker.h>
#include <Mutex.h>
#include <SessionID.h>
#include <Values.h>

#include <fix44/ExecutionReport.h>
#include <fix44/MarketDataIncrementalRefresh.h>
#include <fix44/MarketDataRequest.h>
#include <fix44/MarketDataSnapshotFullRefresh.h>
#include <fix44/NewOrderSingle.h>
#include <fix44/OrderCancelReject.h>
#include <fix44/OrderCancelReplaceRequest.h>
#include <fix44/OrderCancelRequest.h>

#include <boost/lockfree/spsc_queue.hpp>

#include <vector>

class Application : public FIX::Application,
                    public FIX::MessageCracker,
                    public IApplication
{

private:
    std::string username;
    std::string privateKeySeed;
    boost::lockfree::spsc_queue<PriceUpdate> *priceUpdateQueue;
    boost::lockfree::spsc_queue<ExecutionReport> *executionReportQueue;
    std::vector<FIX::SessionID> marketDataSessionIDs{};
    FIX::SessionID orderEntrySessionID{};
    std::unordered_map<std::string, Symbol> *symbolMap;
    std::vector<std::string> symbols{};

    /**
     * Called when quickfix creates a new session.
     * A session comes into and remains in existence for the life of the
     * application. Sessions exist whether or not a counter party is connected to
     * it. As soon as a session is created, you can begin sending messages to it.
     * If no one is logged on, the messages will be sent at the time a connection
     * is established with the counterparty.
     */
    void onCreate(const FIX::SessionID &sessionID) override;

    /**
     * This notifies you when a valid logon has been established with a counter
     * party. This is called when a connection has been established and the FIX
     * logon process has completed with both parties exchanging valid logon
     * messages.
     */
    void onLogon(const FIX::SessionID &sessionID) override;

    /**
     * This notifies you when an FIX session is no longer online.
     * This could happen during a normal logout exchange or because of a forced
     * termination or a loss of network connection.
     */
    void onLogout(const FIX::SessionID &sessionID) override;

    /**
     * This provides you with a peek at the administrative messages that are being
     * sent from your FIX engine to the counter party. This is normally not useful
     * for an application however it is provided for any logging you may wish to
     * do. Notice that the FIX::Message is not const. This allows you to add
     * fields to an adminstrative message before it is sent out.
     */
    void toAdmin(FIX::Message &, const FIX::SessionID &) override;

    /**
     * This is a callback for application messages that are being sent to a
     * counterparty. If you throw a DoNotSend exception in this function, the
     * application will not send the message. This is mostly useful if the
     * application has been asked to resend a message such as an order that is no
     * longer relevant for the current market. Messages that are being resent are
     * marked with the PossDupFlag in the header set to true; If a DoNotSend
     * exception is thrown and the flag is set to true, a sequence reset will be
     * sent in place of the message. If it is set to false, the message will
     * simply not be sent. Notice that the FIX::Message is not const. This allows
     * you to add fields to an application message before it is sent out.
     */
    void toApp(FIX::Message &, const FIX::SessionID &)
        EXCEPT(FIX::DoNotSend) override;

    /**
     * This notifies you when an administrative message is sent from a
     * counterparty to your FIX engine. This can be usefull for doing extra
     * validation on logon messages like validating passwords. Throwing a
     * RejectLogon exception will disconnect the counterparty.
     */
    void fromAdmin(const FIX::Message &, const FIX::SessionID &)
        EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat,
               FIX::IncorrectTagValue, FIX::RejectLogon) override;

    /**
     * This receives application level request.
     * If your application is a sell-side OMS, this is where you will get your new
     * order requests. If you were a buy side, you would get your execution
     * reports here. If a FieldNotFound exception is thrown, the counterparty will
     * receive a reject indicating a conditionally required field is missing. The
     * Message class will throw this exception when trying to retrieve a missing
     * field, so you will rarely need the throw this explicitly. You can also
     * throw an UnsupportedMessageType exception. This will result in the
     * counterparty getting a reject informing them your application cannot
     * process those types of messages. An IncorrectTagValue can also be thrown if
     * a field contains a value you do not support.
     */
    void fromApp(const FIX::Message &message, const FIX::SessionID &sessionID)
        EXCEPT(FIX::FieldNotFound, FIX::IncorrectDataFormat,
               FIX::IncorrectTagValue, FIX::UnsupportedMessageType) override;

    /**
     * Callbacks for specific message types.
     * MessageCracker overloads
     */
    void onMessage(const FIX44::ExecutionReport &,
                   const FIX::SessionID &) override;
    void onMessage(const FIX44::MarketDataSnapshotFullRefresh &message,
                   const FIX::SessionID &sessionID) override;
    void onMessage(const FIX44::MarketDataIncrementalRefresh &message,
                   const FIX::SessionID &sessionID) override;
    void onMessage(const FIX44::MarketDataRequestReject &message,
                   const FIX::SessionID &) override;

public:
    Application(const IConfiguration &conf,
                boost::lockfree::spsc_queue<PriceUpdate> &queue,
                boost::lockfree::spsc_queue<ExecutionReport> &reportQueue,
                std::unordered_map<std::string, Symbol> &symbolMap,
                const std::vector<std::string> &symbols);

    void submitOrder(const std::string &id, const std::string &symbol,
                     PreciseNumber qty, PreciseNumber price,
                     Position position) override;
    bool subscribeToSymbols(const std::vector<std::string> &symbols) override;
};
