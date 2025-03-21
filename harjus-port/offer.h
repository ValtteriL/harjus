#pragma once

#include <QString>
#include <QJsonObject>

struct Offer
{
  double askPrice = 0;
  double askQty = 1;
  double bidPrice = 0;
  double bidQty = 1;
};