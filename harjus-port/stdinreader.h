#include <QObject>
#include <QSocketNotifier>
#include "engine.h"

// object for reading stdin and reacting to input
class StdinReader : public QObject
{
  Q_OBJECT
public:
  StdinReader();

private slots:
  void handleReadyRead();

private:
  QSocketNotifier *m_notifier;
  Engine m_engine;
};