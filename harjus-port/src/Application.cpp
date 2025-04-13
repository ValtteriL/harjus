#include "Application.h"
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

void Application::run()
{
  // TODO: implement application logic
}
