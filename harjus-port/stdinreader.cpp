#include "stdinreader.h"
#include <iostream>
#include <QTextStream>
#include <QCoreApplication>
#include <QJsonDocument>

QJsonObject readJson()
{
  QTextStream in(stdin);
  QString input = in.readLine();
  return QJsonDocument::fromJson(input.toUtf8()).object();
}

StdinReader::StdinReader() : QObject(nullptr), m_notifier(new QSocketNotifier(fileno(stdin), QSocketNotifier::Read, this)), m_engine(Engine::fromJson(readJson()))
{
  connect(m_notifier, &QSocketNotifier::activated, this, &StdinReader::handleReadyRead);
}

void StdinReader::handleReadyRead()
{
  QTextStream in(stdin);
  QString input = in.readLine();

  // quit if stdin closed
  if (input.isNull())
  {
    QCoreApplication::quit();
    return;
  }

  // handle price update
  auto json = QJsonDocument::fromJson(input.toUtf8()).object();
  auto opportunities = m_engine.priceUpdate(json);

  if (opportunities.size() > 0)
  {
    QJsonArray arr;
    for (const auto &opportunity : opportunities)
    {
      arr.append(opportunity.toJson());
    }

    // print resulting array of opportunities in single line
    std::cout << QJsonDocument(arr).toJson(QJsonDocument::Compact).toStdString() << std::endl;
  }
};