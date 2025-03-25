#include <QCoreApplication>
#include <iostream>
#include <string>
#include <QSocketNotifier>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonObject>
#include "engine.h"

QJsonObject readJson()
{
    QTextStream in(stdin);
    QString input = in.readLine();
    return QJsonDocument::fromJson(input.toUtf8()).object();
}

int main()
{
    auto engine = Engine::fromJson(readJson());
    std::cout << "ready" << std::endl;

    QTextStream in(stdin);
    QString input;

    while (!(input = in.readLine()).isNull())
    {
        // handle price update
        auto json = QJsonDocument::fromJson(input.toUtf8()).object();
        auto opportunities = engine.priceUpdate(json);

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
    }

    return 0;
}
