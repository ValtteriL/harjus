#include <iostream>
#include <string>
#include <QJsonDocument>
#include <QJsonObject>
#include "Engine.h"

QJsonObject readJson()
{
    std::string input;
    std::getline(std::cin, input);
    return QJsonDocument::fromJson(QByteArray::fromStdString(input)).object();
}

int main()
{
    auto engine = Engine::fromJson(readJson());
    std::cout << "ready" << std::endl;

    std::string input;

    while (std::getline(std::cin, input))
    {
        // handle price update
        auto json = QJsonDocument::fromJson(QByteArray::fromStdString(input)).object();
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
