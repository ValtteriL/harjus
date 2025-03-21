#include <QCoreApplication>
#include <iostream>
#include <QSocketNotifier>
#include <QTextStream>
#include "stdinreader.h"

int main(int argc, char *argv[])
{
    QCoreApplication a{argc, argv};
    StdinReader reader;
    return a.exec();
}
