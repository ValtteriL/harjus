#pragma once

#include <QString>
#include <QJsonObject>

struct Offer
{
  long double askPrice = 0;
  long double askQty = 0;
  long double bidPrice = 0;
  long double bidQty = 0;
};