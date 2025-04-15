#include "Application.h"
#include "Ed25519.h"
#include <quickfix/Session.h>
#include <iostream>

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
  crack(message, sessionID);
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

void Application::onMessage(const FIX44::ExecutionReport &, const FIX::SessionID &) {}
void Application::onMessage(const FIX44::OrderCancelReject &, const FIX::SessionID &) {}
