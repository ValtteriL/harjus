#include <QCoreApplication>
#include <iostream>
#include <QSocketNotifier>
#include <QTextStream>
#include "stdinreader.h"

int main(int argc, char *argv[])
{
    QCoreApplication a{argc, argv};
    StdinReader reader;
    std::cout << "ready" << std::endl;
    return a.exec();
}
