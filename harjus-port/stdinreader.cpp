#include "stdinreader.h"
#include <iostream>
#include <QTextStream>
#include <QCoreApplication>

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
  std::cout << "Input received: " << input.toStdString() << std::endl;
  // TODO: process price updates here
};